#include "busymark_spellcheck_native.h"

#include <glib.h>
#include <glib/gstdio.h>
#include <pango/pango.h>

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <fstream>
#include <memory>
#include <string>
#include <unordered_set>
#include <utility>
#include <vector>
#include <unistd.h>

#include "hunspell.h"

namespace {

constexpr size_t kMaximumInputBytes = 64 * 1024;

struct GFree {
  void operator()(void* value) const { g_free(value); }
};

template <typename T>
using GOwned = std::unique_ptr<T, GFree>;

struct BusySpellHandleImpl {
  Hunhandle* hunspell = nullptr;
  std::string encoding;
  std::unordered_set<gunichar> word_chars;

  ~BusySpellHandleImpl() {
    if (hunspell != nullptr) Hunspell_destroy(hunspell);
  }
};

struct HunspellSuggestionOwner {
  explicit HunspellSuggestionOwner(Hunhandle* value) : hunspell(value) {}

  Hunhandle* hunspell;
  char** items = nullptr;
  int count = 0;

  ~HunspellSuggestionOwner() {
    if (items != nullptr) Hunspell_free_list(hunspell, &items, count);
  }
};

void set_error(char** out_error, const char* message) {
  if (out_error != nullptr) {
    *out_error = g_strdup(message == nullptr ? "Unknown spelling error" : message);
  }
}

void set_exception(char** out_error, const char* operation) {
  try {
    throw;
  } catch (const std::exception& error) {
    if (out_error != nullptr) {
      *out_error = g_strdup_printf("%s: %s", operation, error.what());
    }
  } catch (...) {
    if (out_error != nullptr) {
      *out_error = g_strdup_printf("%s: unknown native exception", operation);
    }
  }
}

bool validate_utf8_input(const char* value, char** out_error) {
  if (value == nullptr) {
    set_error(out_error, "Missing UTF-8 input");
    return false;
  }
  const size_t length = std::strlen(value);
  if (length > kMaximumInputBytes) {
    set_error(out_error, "Spelling input exceeds the native safety limit");
    return false;
  }
  if (!g_utf8_validate(value, static_cast<gssize>(length), nullptr)) {
    set_error(out_error, "Spelling input is not valid UTF-8");
    return false;
  }
  return true;
}

GOwned<gchar> normalize_nfc(const char* value, char** out_error) {
  if (!validate_utf8_input(value, out_error)) return GOwned<gchar>(nullptr);
  auto* normalized = g_utf8_normalize(value, -1, G_NORMALIZE_NFC);
  if (normalized == nullptr) set_error(out_error, "Could not normalize spelling input");
  return GOwned<gchar>(normalized);
}

GOwned<gchar> convert_text(const char* value,
                           const char* target,
                           const char* source,
                           char** out_error) {
  GError* conversion_error = nullptr;
  auto* converted = g_convert(value, -1, target, source, nullptr, nullptr,
                              &conversion_error);
  if (converted == nullptr && out_error != nullptr) {
    *out_error = g_strdup_printf(
        "Could not convert spelling text from %s to %s: %s", source, target,
        conversion_error == nullptr ? "unknown conversion error"
                                    : conversion_error->message);
  }
  if (conversion_error != nullptr) g_error_free(conversion_error);
  return GOwned<gchar>(converted);
}

GOwned<gchar> to_dictionary(BusySpellHandleImpl* handle,
                            const char* value,
                            char** out_error) {
  auto normalized = normalize_nfc(value, out_error);
  if (!normalized) return GOwned<gchar>(nullptr);
  return convert_text(normalized.get(), handle->encoding.c_str(), "UTF-8",
                      out_error);
}

GOwned<gchar> from_dictionary(BusySpellHandleImpl* handle,
                              const char* value,
                              char** out_error) {
  return convert_text(value, "UTF-8", handle->encoding.c_str(), out_error);
}

std::string trim_ascii(std::string value) {
  const auto first = value.find_first_not_of(" \t\r\n");
  if (first == std::string::npos) return {};
  const auto last = value.find_last_not_of(" \t\r\n");
  return value.substr(first, last - first + 1);
}

void load_word_chars(BusySpellHandleImpl* handle, const char* aff_path) {
  std::ifstream input(aff_path, std::ios::binary);
  std::string raw;
  while (std::getline(input, raw)) {
    raw = trim_ascii(raw);
    constexpr auto directive = "WORDCHARS";
    constexpr auto directive_length = std::char_traits<char>::length(directive);
    if (raw.rfind(directive, 0) != 0 || raw.size() <= directive_length ||
        (raw[directive_length] != ' ' && raw[directive_length] != '\t')) {
      continue;
    }
    raw = trim_ascii(raw.substr(directive_length));
    if (raw.empty()) return;
    char* ignored_error = nullptr;
    auto utf8 = convert_text(raw.c_str(), "UTF-8", handle->encoding.c_str(),
                             &ignored_error);
    g_free(ignored_error);
    if (!utf8) return;
    for (const gchar* cursor = utf8.get(); *cursor != '\0';
         cursor = g_utf8_next_char(cursor)) {
      handle->word_chars.insert(g_utf8_get_char(cursor));
    }
    return;
  }
}

bool is_join_character(BusySpellHandleImpl* handle, gunichar character) {
  return character == '\'' || character == 0x2019 || character == '-' ||
         character == 0x2010 || character == 0x2011 || character == 0x200c ||
         character == 0x200d || handle->word_chars.contains(character);
}

bool is_word_character(gunichar character) {
  return g_unichar_isalpha(character) || g_unichar_ismark(character);
}

struct Candidate {
  guint start;
  guint end;
};

std::vector<guint> character_byte_offsets(const char* text) {
  std::vector<guint> result{0};
  const char* cursor = text;
  while (*cursor != '\0') {
    cursor = g_utf8_next_char(cursor);
    result.push_back(static_cast<guint>(cursor - text));
  }
  return result;
}

bool separator_can_join(BusySpellHandleImpl* handle,
                        const char* text,
                        const std::vector<guint>& offsets,
                        guint from,
                        guint to) {
  if (from >= to || from == 0 || to >= offsets.size() - 1) return false;
  for (guint index = from; index < to; ++index) {
    if (!is_join_character(handle, g_utf8_get_char(text + offsets[index]))) {
      return false;
    }
  }
  return is_word_character(g_utf8_get_char(text + offsets[from - 1])) &&
         is_word_character(g_utf8_get_char(text + offsets[to]));
}

bool supported_encoding(const char* encoding) {
  GIConv to_dictionary = g_iconv_open(encoding, "UTF-8");
  if (to_dictionary == reinterpret_cast<GIConv>(-1)) return false;
  g_iconv_close(to_dictionary);
  GIConv from_dictionary = g_iconv_open("UTF-8", encoding);
  if (from_dictionary == reinterpret_cast<GIConv>(-1)) return false;
  g_iconv_close(from_dictionary);
  return true;
}

std::string dictionary_entry_word(const std::string& raw) {
  std::string word;
  bool escaped = false;
  for (const char value : raw) {
    if (!escaped && (value == '/' || value == '\t' || value == ' ')) break;
    if (!escaped && value == '\\') {
      escaped = true;
      continue;
    }
    word.push_back(value);
    escaped = false;
  }
  if (escaped) word.push_back('\\');
  return word;
}

bool has_loadable_dictionary_entry(Hunhandle* hunspell,
                                   const char* dic_path,
                                   char** out_error) {
  std::ifstream input(dic_path, std::ios::binary);
  std::string raw;
  if (!std::getline(input, raw)) {
    set_error(out_error, "Dictionary has no record count");
    return false;
  }
  raw = trim_ascii(raw);
  if (raw.size() >= 3 && static_cast<unsigned char>(raw[0]) == 0xef &&
      static_cast<unsigned char>(raw[1]) == 0xbb &&
      static_cast<unsigned char>(raw[2]) == 0xbf) {
    raw.erase(0, 3);
  }
  char* count_end = nullptr;
  const auto declared = std::strtoull(raw.c_str(), &count_end, 10);
  if (count_end == raw.c_str() || declared == 0) {
    set_error(out_error, "Dictionary declares no usable records");
    return false;
  }
  // Some established Hunspell dictionaries append a tab-separated format
  // revision to the record count. It is metadata, not another dictionary
  // entry; accept only an all-numeric suffix so arbitrary malformed headers
  // do not pass structural validation.
  while (*count_end == ' ' || *count_end == '\t') ++count_end;
  while (*count_end >= '0' && *count_end <= '9') ++count_end;
  if (*count_end != '\0') {
    set_error(out_error, "Dictionary has a malformed record count");
    return false;
  }

  size_t records = 0;
  bool accepted = false;
  while (std::getline(input, raw)) {
    if (!raw.empty() && raw.back() == '\r') raw.pop_back();
    if (raw.empty()) continue;
    ++records;
    if (!accepted) {
      const auto word = dictionary_entry_word(raw);
      if (!word.empty() && Hunspell_spell(hunspell, word.c_str()) != 0) {
        accepted = true;
      }
    }
  }
  // Hunspell accepts long-lived dictionaries whose advisory count has drifted
  // from the physical line count (for example the pinned French resource).
  // The security/correctness invariant here is that a positive claim is backed
  // by at least one real record that the loaded engine itself accepts.
  if (records == 0) {
    set_error(out_error, "Dictionary contains no records");
    return false;
  }
  if (!accepted) {
    set_error(out_error, "Dictionary loaded no verifiable entries");
    return false;
  }
  return true;
}

}  // namespace

struct BusySpellHandle : BusySpellHandleImpl {};

int busy_spell_open(const char* aff_path_utf8,
                    const char* dic_path_utf8,
                    BusySpellHandle** out_handle,
                    char** out_error) {
  if (out_handle != nullptr) *out_handle = nullptr;
  if (out_error != nullptr) *out_error = nullptr;
  if (out_handle == nullptr || aff_path_utf8 == nullptr ||
      dic_path_utf8 == nullptr) {
    set_error(out_error, "Dictionary paths and output handle are required");
    return BUSY_SPELL_ERROR;
  }
  if (!g_file_test(aff_path_utf8, G_FILE_TEST_IS_REGULAR) ||
      !g_file_test(dic_path_utf8, G_FILE_TEST_IS_REGULAR) ||
      g_access(aff_path_utf8, R_OK) != 0 || g_access(dic_path_utf8, R_OK) != 0) {
    set_error(out_error, "Dictionary pair is missing or unreadable");
    return BUSY_SPELL_ERROR;
  }
  try {
    auto handle = std::make_unique<BusySpellHandle>();
    handle->hunspell = Hunspell_create(aff_path_utf8, dic_path_utf8);
    if (handle->hunspell == nullptr) {
      set_error(out_error, "Hunspell could not open the dictionary pair");
      return BUSY_SPELL_ERROR;
    }
    const char* encoding = Hunspell_get_dic_encoding(handle->hunspell);
    if (encoding == nullptr || *encoding == '\0' || !supported_encoding(encoding)) {
      set_error(out_error, "Dictionary declares an unsupported encoding");
      return BUSY_SPELL_ERROR;
    }
    handle->encoding = encoding;
    if (!has_loadable_dictionary_entry(handle->hunspell, dic_path_utf8,
                                       out_error)) {
      return BUSY_SPELL_ERROR;
    }
    load_word_chars(handle.get(), aff_path_utf8);
    *out_handle = handle.release();
    return BUSY_SPELL_ACCEPTED;
  } catch (...) {
    set_exception(out_error, "Could not open dictionary");
    return BUSY_SPELL_ERROR;
  }
}

void busy_spell_close(BusySpellHandle* handle) {
  try {
    delete handle;
  } catch (...) {
  }
}

int busy_spell_check(BusySpellHandle* handle,
                     const char* word_utf8,
                     char** out_error) {
  if (out_error != nullptr) *out_error = nullptr;
  if (handle == nullptr) {
    set_error(out_error, "Dictionary handle is closed");
    return BUSY_SPELL_ERROR;
  }
  try {
    auto encoded = to_dictionary(handle, word_utf8, out_error);
    if (!encoded) return BUSY_SPELL_ERROR;
    return Hunspell_spell(handle->hunspell, encoded.get()) == 0
               ? BUSY_SPELL_REJECTED
               : BUSY_SPELL_ACCEPTED;
  } catch (...) {
    set_exception(out_error, "Could not check word");
    return BUSY_SPELL_ERROR;
  }
}

int busy_spell_suggest(BusySpellHandle* handle,
                       const char* word_utf8,
                       char*** out_items,
                       size_t* out_count,
                       char** out_error) {
  if (out_items != nullptr) *out_items = nullptr;
  if (out_count != nullptr) *out_count = 0;
  if (out_error != nullptr) *out_error = nullptr;
  if (handle == nullptr || out_items == nullptr || out_count == nullptr) {
    set_error(out_error, "Dictionary handle and suggestion outputs are required");
    return BUSY_SPELL_ERROR;
  }
  try {
    auto encoded = to_dictionary(handle, word_utf8, out_error);
    if (!encoded) return BUSY_SPELL_ERROR;
    HunspellSuggestionOwner hunspell_items(handle->hunspell);
    const int count = Hunspell_suggest(handle->hunspell, &hunspell_items.items,
                                       encoded.get());
    if (count < 0) {
      set_error(out_error, "Hunspell suggestion generation failed");
      return BUSY_SPELL_ERROR;
    }
    hunspell_items.count = count;
    std::vector<GOwned<gchar>> copied;
    copied.reserve(static_cast<size_t>(count));
    for (int index = 0; index < count; ++index) {
      auto value = from_dictionary(handle, hunspell_items.items[index], out_error);
      if (!value) {
        return BUSY_SPELL_ERROR;
      }
      copied.push_back(std::move(value));
    }
    if (!copied.empty()) {
      auto** result = static_cast<char**>(g_malloc_n(copied.size(), sizeof(char*)));
      for (size_t index = 0; index < copied.size(); ++index) {
        result[index] = copied[index].release();
      }
      *out_items = result;
      *out_count = copied.size();
    }
    return BUSY_SPELL_ACCEPTED;
  } catch (...) {
    set_exception(out_error, "Could not generate suggestions");
    return BUSY_SPELL_ERROR;
  }
}

int busy_spell_add(BusySpellHandle* handle,
                   const char* word_utf8,
                   char** out_error) {
  if (out_error != nullptr) *out_error = nullptr;
  if (handle == nullptr) {
    set_error(out_error, "Dictionary handle is closed");
    return BUSY_SPELL_ERROR;
  }
  try {
    auto encoded = to_dictionary(handle, word_utf8, out_error);
    if (!encoded) return BUSY_SPELL_ERROR;
    if (Hunspell_add(handle->hunspell, encoded.get()) != 0) {
      set_error(out_error, "Hunspell could not add the custom word");
      return BUSY_SPELL_ERROR;
    }
    return BUSY_SPELL_ACCEPTED;
  } catch (...) {
    set_exception(out_error, "Could not add custom word");
    return BUSY_SPELL_ERROR;
  }
}

int busy_spell_dictionary_encoding(BusySpellHandle* handle,
                                   char** out_encoding,
                                   char** out_error) {
  if (out_encoding != nullptr) *out_encoding = nullptr;
  if (out_error != nullptr) *out_error = nullptr;
  if (handle == nullptr || out_encoding == nullptr) {
    set_error(out_error, "Dictionary handle and encoding output are required");
    return BUSY_SPELL_ERROR;
  }
  *out_encoding = g_strdup(handle->encoding.c_str());
  return BUSY_SPELL_ACCEPTED;
}

int busy_spell_tokenize(BusySpellHandle* handle,
                        const char* prose_utf8,
                        const char* language_utf8,
                        BusySpellTokenRange** out_ranges,
                        size_t* out_count,
                        char** out_error) {
  if (out_ranges != nullptr) *out_ranges = nullptr;
  if (out_count != nullptr) *out_count = 0;
  if (out_error != nullptr) *out_error = nullptr;
  if (handle == nullptr || out_ranges == nullptr || out_count == nullptr) {
    set_error(out_error, "Dictionary handle and token outputs are required");
    return BUSY_SPELL_ERROR;
  }
  if (!validate_utf8_input(prose_utf8, out_error)) return BUSY_SPELL_ERROR;
  try {
    const auto offsets = character_byte_offsets(prose_utf8);
    const int character_count = static_cast<int>(offsets.size() - 1);
    std::vector<PangoLogAttr> attributes(static_cast<size_t>(character_count + 1));
    PangoLanguage* language = nullptr;
    if (language_utf8 != nullptr && *language_utf8 != '\0') {
      language = pango_language_from_string(language_utf8);
    }
    pango_get_log_attrs(prose_utf8, static_cast<int>(std::strlen(prose_utf8)),
                        -1, language, attributes.data(), character_count + 1);

    std::vector<Candidate> candidates;
    for (guint index = 0; index < static_cast<guint>(character_count); ++index) {
      if (!attributes[index].is_word_start) continue;
      guint end = index + 1;
      while (end <= static_cast<guint>(character_count) &&
             !attributes[end].is_word_end) {
        ++end;
      }
      if (end > static_cast<guint>(character_count)) break;
      while (index > 0 &&
             is_join_character(
                 handle, g_utf8_get_char(prose_utf8 + offsets[index - 1]))) {
        --index;
      }
      while (end < static_cast<guint>(character_count) &&
             is_join_character(handle,
                               g_utf8_get_char(prose_utf8 + offsets[end]))) {
        ++end;
      }
      bool contains_letter = false;
      for (guint cursor = index; cursor < end; ++cursor) {
        if (is_word_character(g_utf8_get_char(prose_utf8 + offsets[cursor]))) {
          contains_letter = true;
          break;
        }
      }
      if (contains_letter) candidates.push_back({index, end});
      index = end - 1;
    }

    std::vector<Candidate> merged;
    for (const auto candidate : candidates) {
      if (!merged.empty() &&
          (candidate.start <= merged.back().end ||
           separator_can_join(handle, prose_utf8, offsets, merged.back().end,
                              candidate.start))) {
        merged.back().end = std::max(merged.back().end, candidate.end);
      } else {
        merged.push_back(candidate);
      }
    }
    if (!merged.empty()) {
      auto* result = static_cast<BusySpellTokenRange*>(
          g_malloc_n(merged.size(), sizeof(BusySpellTokenRange)));
      for (size_t index = 0; index < merged.size(); ++index) {
        result[index] = {offsets[merged[index].start], offsets[merged[index].end],
                         merged[index].start, merged[index].end};
      }
      *out_ranges = result;
      *out_count = merged.size();
    }
    return BUSY_SPELL_ACCEPTED;
  } catch (...) {
    set_exception(out_error, "Could not tokenize prose");
    return BUSY_SPELL_ERROR;
  }
}

void busy_spell_free_suggestions(char** items, size_t count) {
  if (items == nullptr) return;
  for (size_t index = 0; index < count; ++index) g_free(items[index]);
  g_free(items);
}

void busy_spell_free_token_ranges(BusySpellTokenRange* ranges) { g_free(ranges); }

void busy_spell_free_string(char* value) { g_free(value); }

#include <stddef.h>
#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct BusySpellHandle BusySpellHandle;

typedef struct BusySpellTokenRange {
  uint32_t utf8_start;
  uint32_t utf8_end;
  uint32_t character_start;
  uint32_t character_end;
} BusySpellTokenRange;

enum BusySpellStatus {
  BUSY_SPELL_ERROR = -1,
  BUSY_SPELL_REJECTED = 0,
  BUSY_SPELL_ACCEPTED = 1,
};

FFI_PLUGIN_EXPORT int busy_spell_open(const char* aff_path_utf8,
                                      const char* dic_path_utf8,
                                      BusySpellHandle** out_handle,
                                      char** out_error);
FFI_PLUGIN_EXPORT void busy_spell_close(BusySpellHandle* handle);
FFI_PLUGIN_EXPORT int busy_spell_check(BusySpellHandle* handle,
                                       const char* word_utf8,
                                       char** out_error);
FFI_PLUGIN_EXPORT int busy_spell_suggest(BusySpellHandle* handle,
                                         const char* word_utf8,
                                         char*** out_items,
                                         size_t* out_count,
                                         char** out_error);
FFI_PLUGIN_EXPORT int busy_spell_add(BusySpellHandle* handle,
                                     const char* word_utf8,
                                     char** out_error);
FFI_PLUGIN_EXPORT int busy_spell_dictionary_encoding(BusySpellHandle* handle,
                                                      char** out_encoding,
                                                      char** out_error);

/// Calls Pango with the complete UTF-8 prose run. The C bitfield attributes are
/// copied into stable byte/character ranges rather than exposed through FFI.
FFI_PLUGIN_EXPORT int busy_spell_tokenize(BusySpellHandle* handle,
                                          const char* prose_utf8,
                                          const char* language_utf8,
                                          BusySpellTokenRange** out_ranges,
                                          size_t* out_count,
                                          char** out_error);

FFI_PLUGIN_EXPORT void busy_spell_free_suggestions(char** items, size_t count);
FFI_PLUGIN_EXPORT void busy_spell_free_token_ranges(BusySpellTokenRange* ranges);
FFI_PLUGIN_EXPORT void busy_spell_free_string(char* value);

#ifdef __cplusplus
}
#endif

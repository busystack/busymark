/// Visible addresses are not prose in either Source or rich editor fields.
final spellingPlainAddress = RegExp(
  r'''(?:https?|ftp)://[^\s<>()]+|www\.[^\s<>()]+|[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}''',
  caseSensitive: false,
);

// Keyboard input and program output follow the same prose policy as code.
const spellingTechnicalHtmlInlineTags = {'kbd', 'samp'};

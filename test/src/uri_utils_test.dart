import 'package:busymark/src/core/uri_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('external launch policy is an explicit safe-list', () {
    expect(isLaunchableExternalUri(Uri.parse('https://example.com')), isTrue);
    expect(isLaunchableExternalUri(Uri.parse('http://example.com')), isTrue);
    expect(
      isLaunchableExternalUri(Uri.parse('mailto:docs@example.com')),
      isTrue,
    );
    expect(isLaunchableExternalUri(Uri.parse('tel:+15551234567')), isTrue);

    expect(isLaunchableExternalUri(Uri.parse('ftp://example.com')), isFalse);
    expect(isLaunchableExternalUri(Uri.parse('docs://topic/intro')), isFalse);
    expect(isLaunchableExternalUri(Uri.parse('file:///tmp/topic.md')), isFalse);
    expect(isLaunchableExternalUri(Uri.parse('javascript:alert(1)')), isFalse);
    expect(
      isLaunchableExternalUri(Uri.parse('data:text/plain,hello')),
      isFalse,
    );
  });

  test('scheme detection remains broader than launch policy', () {
    expect(hasUriScheme('docs://topic/intro'), isTrue);
    expect(hasUriScheme('file:///tmp/topic.md'), isTrue);
    expect(hasUriScheme('relative/topic.md'), isFalse);
  });

  test('remote resources only allow http and https', () {
    expect(isRemoteResourceUriScheme('https'), isTrue);
    expect(isRemoteResourceUriScheme('http'), isTrue);
    expect(isRemoteResourceUriScheme('mailto'), isFalse);
    expect(isRemoteResourceUriScheme('file'), isFalse);
  });
}

/// An ordinary link destination with optional Writerside semantic context.
class LinkDestination {
  const LinkDestination(this.href, {this.origin});
  final String href;
  final String? origin;
}

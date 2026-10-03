import 'package:path/path.dart' as p;

// Only names emitted by the topic writers. A user file merely containing
// "busymark" is not an internal path. Moves must classify both endpoints.
final _topicStagingName = RegExp(
  r'^\..+\.busymark-(?:topic-create|safe-delete(?:-quarantine)?)-\d+-\d+-\d+$',
);

bool isBusyMarkTopicStagingPath(String path) =>
    _topicStagingName.hasMatch(p.basename(path));

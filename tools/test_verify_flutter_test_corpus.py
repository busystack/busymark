"""Adversarial unit fixtures for corpus qualification, not execution evidence."""
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from tools.git_native_build_receipt import sources
from tools.verify_flutter_test_corpus import verify


class CorpusQualificationTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='bsg-corpus-unit-')
        self.addCleanup(self.temporary.cleanup)
        self.workspace = Path(self.temporary.name)
        self.root = self.workspace/'busymark'
        env = dict(os.environ, GIT_CONFIG_GLOBAL='/dev/null', GIT_CONFIG_NOSYSTEM='1')
        for name in ['busymark', 'busystack_git_flutter', 'busystack_git']:
            repo = self.workspace/name
            (repo/'lib').mkdir(parents=True)
            (repo/'lib/example.dart').write_text('const example = 1;\n')
            if name == 'busymark':
                (repo/'test/support').mkdir(parents=True)
                (repo/'test/support/fixture.txt').write_text('native fixture')
                for filename in ['a_test.dart', 'b_test.dart']:
                    (repo/'test'/filename).write_text('void main() {}\n')
            for args in [['init', '-b', 'main'], ['add', '.'],
                         ['-c', 'user.name=Unit fixture', '-c', 'user.email=unit@example.invalid',
                          '-c', 'commit.gpgSign=false', 'commit', '-m', 'Unit fixture']]:
                subprocess.run(['git', '-C', str(repo), *args], env=env, check=True,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.flutter = self.workspace/'official-flutter'
        self.flutter.write_text('unit fixture path only; never executed')
        self.log = self.workspace/'unit-fixture.log'
        self.log.write_text('00:01 +2: All tests passed!\n')
        files = ['test/a_test.dart', 'test/b_test.dart']
        self.data = {'status': 'passed', 'allDiscoveredCasesExercised': True,
                     'sources': sources(self.workspace), 'discoveredFiles': 2,
                     'filesSHA256': {name: hashlib.sha256((self.root/name).read_bytes()).hexdigest() for name in files},
                     'totalPassed': 2, 'totalSkipped': 0,
                     'batches': [{'status': 'passed', 'exitCode': 0, 'skipped': 0, 'passed': 2,
                                  'files': files, 'log': str(self.log),
                                  'logSHA256': hashlib.sha256(self.log.read_bytes()).hexdigest(),
                                  'command': [str(self.flutter), 'test', '--no-pub', '--concurrency=2',
                                              '--reporter=expanded', *files]}]}
        self.receipt = self.workspace/'unit-fixture-receipt.json'

    def qualify(self, data=None):
        self.receipt.write_text(json.dumps(data or self.data))
        return verify(self.receipt, self.root, self.flutter)

    def test_complete_unit_fixture_and_documentation_only_change(self):
        (self.root/'README.md').write_text('Documentation only')
        self.assertEqual(self.qualify()['passed'], 2)

    def test_missing_or_duplicate_file_is_rejected(self):
        for files in [['test/a_test.dart'], ['test/a_test.dart', 'test/a_test.dart']]:
            data = copy.deepcopy(self.data)
            data['batches'][0]['files'] = files
            data['batches'][0]['command'] = data['batches'][0]['command'][:5]+files
            with self.assertRaises(ValueError): self.qualify(data)

    def test_changed_production_or_entry_file_is_rejected(self):
        for path in [self.root/'test/a_test.dart', self.workspace/'busystack_git_flutter/lib/example.dart']:
            before = path.read_text()
            path.write_text('changed')
            with self.assertRaises(ValueError): self.qualify()
            path.write_text(before)

    def test_changed_imported_test_fixture_is_rejected(self):
        (self.root/'test/support/fixture.txt').write_text('changed native fixture')
        with self.assertRaises(subprocess.CalledProcessError): self.qualify()

    def test_changed_log_is_rejected(self):
        self.log.write_text('00:01 +2: Some tests failed.\n')
        with self.assertRaises(ValueError): self.qualify()

    def test_filter_failed_or_skipped_batch_is_rejected(self):
        for change in [{'skipped': 1}, {'exitCode': 1}, {'status': 'running'},
                       {'command': self.data['batches'][0]['command']+['--plain-name', 'narrow']}]:
            data = copy.deepcopy(self.data)
            data['batches'][0].update(change)
            with self.assertRaises(ValueError): self.qualify(data)


if __name__ == '__main__':
    unittest.main()

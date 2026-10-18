"""Negative controls for reference-based content recognition, not performance."""
from pathlib import Path
import sys
import unittest

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from application_content_observer import ContentReference


class ContentReferenceTest(unittest.TestCase):
    def frame(self, heading='Session fixture 0', body='Restored content 0.'):
        image = Image.new('RGB', (765, 443), (39, 39, 39))
        draw = ImageDraw.Draw(image)
        font = ImageFont.load_default(size=18)
        draw.text((3, 1), heading, fill=(230, 230, 230), font=font)
        draw.text((3, 40), body, fill=(230, 230, 230), font=font)
        return image

    def reference(self):
        return ContentReference(self.frame(), [(1, 0, 55, 8), (1, 10, 55, 17)])

    def test_correct_requested_content_is_recognized(self):
        self.assertTrue(self.reference().compare(self.frame())['matched'])

    def test_blank_and_loading_are_rejected_even_when_global_error_passes(self):
        for observed in [Image.new('RGB', (765, 443), (39, 39, 39)),
                         self.frame('Loading...', '')]:
            result = self.reference().compare(observed)
            self.assertLess(result['globalError'], 1.5)
            self.assertFalse(result['matched'])

    def test_wrong_document_with_shared_prefix_and_one_changed_digit_is_rejected(self):
        result = self.reference().compare(self.frame('Session fixture 1', 'Restored content 1.'))
        self.assertLess(result['globalError'], 1.5)
        self.assertFalse(result['matched'])

    def test_matching_heading_cannot_hide_missing_body(self):
        self.assertFalse(self.reference().compare(self.frame(body=''))['matched'])

    def test_blank_reference_cannot_be_calibrated_as_content(self):
        with self.assertRaisesRegex(ValueError, 'insufficient'):
            ContentReference(Image.new('RGB', (765, 443), (39, 39, 39)), [(1, 0, 55, 17)])

    def test_regions_are_explicit_and_bounded(self):
        for regions in [[], [(-1, 0, 55, 17)], [(0, 0, 221, 120)]]:
            with self.assertRaises(ValueError):
                ContentReference(self.frame(), regions)


if __name__ == '__main__':
    unittest.main()

"""Content-reference comparison for an already identified, owned window crop.

This does not establish window ownership, interaction or durable completion.
Calibrate a ready reference separately. Regions use the 220x120 comparison
coordinates and must contain the requested text/structure, excluding cursors
and animations. A background-only reference is invalid. Keep probe deadlines
and existing global error limits unchanged when adopting this predicate.
"""
from collections import Counter

from PIL import ImageChops, ImageStat


class ContentReference:
    size = (220, 120)

    def __init__(self, reference, regions):
        self.image = reference.convert('RGB').resize(self.size)
        self.background = Counter(self.image.getdata()).most_common(1)[0][0]
        pixels = self.image.load()
        self.tiles = []
        for left, top, right, bottom in regions:
            if not (0 <= left < right <= self.size[0] and 0 <= top < bottom <= self.size[1]):
                raise ValueError('Content region is outside comparison coordinates')
            region_tiles = []
            for y in range(top, bottom, 4):
                for x in range(left, right, 4):
                    points = [(xx, yy) for yy in range(y, min(y + 4, bottom))
                              for xx in range(x, min(x + 4, right))
                              if max(abs(a - b) for a, b in zip(pixels[xx, yy], self.background)) >= 24]
                    if len(points) >= 2:
                        region_tiles.append(points)
            if sum(map(len, region_tiles)) < 16:
                raise ValueError('Content region has insufficient reference structure')
            self.tiles.extend(region_tiles)
        if not self.tiles:
            raise ValueError('At least one requested-content region is required')

    def compare(self, observed):
        observed = observed.convert('RGB').resize(self.size)
        difference = ImageChops.difference(observed, self.image)
        global_error = sum(ImageStat.Stat(difference).mean) / 3
        pixels = difference.load()
        # Small informative tiles prevent a large empty background, shared
        # heading or unchanged prefix from diluting missing/different text.
        maximum = max(sum(sum(pixels[x, y]) for x, y in tile) / (3 * len(tile))
                      for tile in self.tiles)
        return {'matched': global_error < 1.5 and maximum <= 12,
                'globalError': global_error, 'maximumContentTileError': maximum}

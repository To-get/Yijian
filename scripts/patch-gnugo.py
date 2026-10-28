"""Fix GNU Go 3.8's empty-array pointer underflow with modern Clang."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / 'vendor/gnugo-3.8/utils/gg_utils.c'
source = path.read_text()
marker = '  char *end = (char *) base + width * (nel - 1);'
if 'Yijian: empty collections' not in source:
    assert marker in source
    source = source.replace(marker, '''  char *end;
  /* Yijian: empty collections must not form a pointer before the array.
   * Local compatibility fix, 2026-10-28. Sorting 0 or 1 elements is a no-op.
   */
  if (nel < 2)
    return;
  end = (char *) base + width * (nel - 1);''')
    path.write_text(source)

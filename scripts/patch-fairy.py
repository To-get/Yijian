"""Expose upstream rule/notation APIs over the engine's existing local pipe."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / 'vendor/fairy-stockfish/src/uci.cpp'
text = path.read_text()
if 'token == "yijian"' not in text:
    text = text.replace('#include "evaluate.h"', '#include "evaluate.h"\n#include "apiutil.h"')
    marker = '      else if (token == "d")        sync_cout << pos << sync_endl;'
    extension = r'''
      // Yijian local UI adapter. Rule decisions and SAN remain upstream code.
      else if (token == "yijian")
      {
          Value result = VALUE_DRAW;
          bool ended = pos.is_immediate_game_end(result);
          string reason = ended ? "variant" : "ongoing";
          if (!ended && has_insufficient_material(WHITE, pos) && has_insufficient_material(BLACK, pos))
              ended = true, result = VALUE_DRAW, reason = "material";
          auto legal = MoveList<LEGAL>(pos);
          if (!ended && legal.size() == 0)
              ended = true, result = pos.checkers() ? pos.checkmate_value() : pos.stalemate_value(),
              reason = pos.checkers() ? "mate" : "stalemate";
          if (!ended && pos.is_optional_game_end(result))
              ended = true, reason = "rule";
          if (pos.side_to_move() == BLACK)
              result = -result;
          sync_cout << "fen " << pos.fen()
                    << "\ncheck " << bool(pos.checkers())
                    << "\nresult " << (!ended ? "*" : result == 0 ? "1/2-1/2" : result > 0 ? "1-0" : "0-1")
                    << "\nreason " << reason << sync_endl;
          for (Move m : legal)
              sync_cout << "move " << UCI::move(pos, m) << "|"
                        << SAN::move_to_san(pos, m, Options["UCI_Variant"] == "xiangqi" ? NOTATION_XIANGQI_WXF : NOTATION_SAN)
                        << sync_endl;
          sync_cout << "yijianok" << sync_endl;
      }
'''
    assert marker in text
    path.write_text(text.replace(marker, marker + extension))

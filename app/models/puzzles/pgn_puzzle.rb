require 'pgn'

class PGNPuzzle
  attr_accessor :puzzle_id, :initial_fen, :moves_uci, :lines_tree,
                :rating, :rating_deviation, :popularity, :num_plays, :themes

  @@puzzles = []

  def initialize(puzzle_id:, initial_fen:, moves_uci:, rating: nil, rating_deviation: nil, popularity: nil, num_plays: nil, themes: [])
    @puzzle_id = puzzle_id
    @initial_fen = initial_fen
    @moves_uci = moves_uci
    @rating = rating
    @rating_deviation = rating_deviation
    @popularity = popularity
    @num_plays = num_plays
    @themes = themes
    @lines_tree = nil
    calculate_lines_tree
  end

  # Load puzzles from a local or uploaded PGN file
  def self.load_from_pgn(file_path)
    @@puzzles = []
    File.open(file_path) do |file|
      PGN.parse(file.read).each_with_index do |game, idx|
        fen = game.tags["FEN"] || game.initial_position.to_fen
        moves_uci = game.moves.map(&:to_s)
        themes = (game.tags["Themes"] || "").split(",")
        puzzle = PGNPuzzle.new(
          puzzle_id: game.tags["PuzzleID"] || idx,
          initial_fen: fen,
          moves_uci: moves_uci,
          rating: game.tags["Rating"]&.to_i,
          rating_deviation: game.tags["RatingDeviation"]&.to_i,
          popularity: game.tags["Popularity"]&.to_i,
          num_plays: game.tags["NumPlays"]&.to_i,
          themes: themes
        )
        @@puzzles << puzzle
      end
    end
  end

  # Find puzzle by puzzle_id
  def self.find_by_puzzle_id(pid)
    @@puzzles.find { |p| p.puzzle_id.to_s == pid.to_s }
  end

  # Return all loaded puzzles
  def self.all
    @@puzzles
  end

  # Sorts puzzles by the order in which they show up in puzzle_ids
  def self.find_by_sorted(puzzle_ids)
    puzzle_ids = puzzle_ids.map(&:to_s)
    @@puzzles.select { |p| puzzle_ids.include?(p.puzzle_id.to_s) }
             .sort_by { |p| puzzle_ids.index(p.puzzle_id.to_s) }
  end

  # Puzzle format used by blitz tactics game modes
  def bt_puzzle_data
    {
      id: puzzle_id,
      fen: initial_fen,
      lines: lines_tree,
      initialMove: {
        uci: moves_uci[0],
      }
    }
  end

  # Data format used by puzzle pages
  def puzzle_data
    {
      initial_fen: initial_fen,
      initial_move_uci: moves_uci[0],
      lines: lines_tree,
    }
  end

  def metadata
    {
      rating: rating,
      rating_deviation: rating_deviation,
      popularity: popularity,
      num_plays: num_plays,
      themes: themes,
    }
  end

  def as_json(options={})
    {
      puzzle_data: puzzle_data,
      metadata: metadata,
    }
  end

  def is_reportable?
    false
  end

  def initial_move_uci
    moves_uci[0]
  end

  # Converts an array of puzzle moves to lines tree format
  def calculate_lines_tree
    lines_tree_root = {}
    lines_tree = lines_tree_root
    self.moves_uci[1..-2].each do |move_uci|
      lines_tree[move_uci] = {}
      lines_tree = lines_tree[move_uci]
    end
    last_move_uci = moves_uci[-1]
    lines_tree[last_move_uci] = 'win'
    self.lines_tree = lines_tree_root
  end
end
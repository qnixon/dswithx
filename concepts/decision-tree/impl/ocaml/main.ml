(* A decision tree classifier (CART with Gini impurity), using only OCaml's
   standard library.

   Grows a tree on the training days by always making the split that leaves
   the two sides purest, then predicts rain for the test days. Prints the tree
   in preorder: each node is either a split (feature and threshold) or a leaf
   (its prediction). *)

let features = [| "humidity"; "pressure"; "wind" |]
let max_depth = 3
let min_size = 5

(* One day: its feature values, in the order of features, and "yes" or "no". *)
type day = { x : float array; label : string }

(* A tree is a leaf holding its prediction or a split holding a feature
   position, a threshold, and two smaller trees. The type names itself, and
   Split carries an inline record, so its fields have names. *)
type tree =
  | Leaf of string
  | Split of { feature : int; threshold : float; left : tree; right : tree }

(* The training days and the test days. The header gives each column's
   position. *)
let read_days path =
  In_channel.with_open_text path (fun ic ->
      match In_channel.input_lines ic with
      | [] -> failwith "empty file"
      | header :: rows ->
          let names = String.split_on_char ',' header in
          let col name =
            match List.find_index (String.equal name) names with
            | Some i -> i
            | None -> failwith ("column not found: " ^ name)
          in
          let parse row =
            let fields = Array.of_list (String.split_on_char ',' row) in
            let x = Array.map (fun name -> float_of_string fields.(col name)) features in
            (fields.(col "split") = "train", { x; label = fields.(col "rain") })
          in
          let tagged = List.map parse (List.filter (fun row -> row <> "") rows) in
          let train, test = List.partition fst tagged in
          (List.map snd train, List.map snd test))

let count_yes days = List.length (List.filter (fun d -> d.label = "yes") days)
let size days = float_of_int (List.length days)

(* Chance that two days drawn at random (with replacement) disagree. *)
let gini days =
  let p = float_of_int (count_yes days) /. size days in
  1. -. (p *. p) -. ((1. -. p) *. (1. -. p))

(* Strictly more than half must be rainy, so an even split predicts "no". *)
let majority days = if 2 * count_yes days > List.length days then "yes" else "no"

(* The days at or below the threshold, then the days above it. *)
let divide f threshold days = List.partition (fun d -> d.x.(f) <= threshold) days

(* The weighted Gini impurity left after splitting at this feature and
   threshold. *)
let score days f threshold =
  let left, right = divide f threshold days in
  ((size left *. gini left) +. (size right *. gini right)) /. size days

(* Every candidate split: features in column order, and for each, the
   midpoints between neighboring distinct values, from smallest to largest.
   List.sort_uniq sorts and drops duplicates. *)
let candidates days =
  let rec midpoints f = function
    | a :: (b :: _ as rest) -> (f, (a +. b) /. 2.) :: midpoints f rest
    | _ -> []
  in
  List.concat_map
    (fun f -> midpoints f (List.sort_uniq compare (List.map (fun d -> d.x.(f)) days)))
    (List.init (Array.length features) Fun.id)

(* Some (score, feature, threshold) with the lowest score, or None when every
   feature has a single value. Only a strictly lower score replaces the best
   so far, so on a tie the first split tried wins. *)
let best_split days =
  List.fold_left
    (fun best (f, t) ->
      let s = score days f t in
      match best with
      | Some (best_score, _, _) when best_score <= s -> best
      | _ -> Some (s, f, t))
    None (candidates days)

(* Grow the tree from the root at depth 0. A node becomes a leaf when it is
   pure, has fewer than min_size days, reaches max_depth, or no split makes
   the sides purer. let rec lets grow call itself. *)
let rec grow depth days =
  let impurity = gini days in
  let leaf = Leaf (majority days) in
  if impurity = 0. || List.length days < min_size || depth = max_depth then leaf
  else
    match best_split days with
    | Some (s, feature, threshold) when s < impurity ->
        let left, right = divide feature threshold days in
        Split { feature; threshold; left = grow (depth + 1) left; right = grow (depth + 1) right }
    | _ -> leaf

(* Follow the splits down to a leaf. The match must cover both kinds of node,
   or the compiler warns. *)
let rec predict tree x =
  match tree with
  | Leaf label -> label
  | Split { feature; threshold; left; right } ->
      predict (if x.(feature) <= threshold then left else right) x

(* Every node in preorder: the node itself, then its left side, then its
   right. *)
let rec preorder tree =
  match tree with
  | Leaf _ -> [ tree ]
  | Split { left; right; _ } -> (tree :: preorder left) @ preorder right

let count_correct tree days =
  List.length (List.filter (fun d -> predict tree d.x = d.label) days)

let () =
  let train, test = read_days Sys.argv.(1) in
  let tree = grow 0 train in
  let nodes = preorder tree in
  Printf.printf "train_count %d\n" (List.length train);
  Printf.printf "test_count %d\n" (List.length test);
  (* iteri numbers the nodes from 0, so each k is i + 1. *)
  List.iteri
    (fun i node ->
      match node with
      | Leaf label -> Printf.printf "node_%d_predict %s\n" (i + 1) label
      | Split { feature; threshold; _ } ->
          Printf.printf "node_%d_feature %s\n" (i + 1) features.(feature);
          Printf.printf "node_%d_threshold %.6f\n" (i + 1) threshold)
    nodes;
  let is_leaf = function Leaf _ -> true | Split _ -> false in
  Printf.printf "leaves %d\n" (List.length (List.filter is_leaf nodes));
  let correct = count_correct tree test in
  Printf.printf "train_accuracy %.6f\n" (float_of_int (count_correct tree train) /. size train);
  Printf.printf "correct %d\n" correct;
  Printf.printf "accuracy %.6f\n" (float_of_int correct /. size test)

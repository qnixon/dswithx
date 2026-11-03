(* Categorical naive Bayes with add-one (Laplace) smoothing, using only
   OCaml's standard library.

   Learns P(label) and P(feature value | label) by counting training rows,
   then labels each test row with the label that has the highest
   log-probability. Counts live in Hashtbl, the standard library's hash
   table. *)

let features = [ "has_link"; "mentions_money"; "known_sender" ]

(* Every data line, with its fields paired to the header's column names, such
   as ("label", "spam"). A list of pairs like this is an association list. *)
let read_rows path =
  In_channel.with_open_text path (fun ic ->
      match In_channel.input_lines ic with
      | [] -> failwith "empty file"
      | header :: rows ->
          let names = String.split_on_char ',' header in
          rows
          |> List.filter (fun row -> row <> "")
          |> List.map (fun row ->
                 List.combine names (String.split_on_char ',' row)))

(* The value in a named column. List.assoc raises Not_found if it's missing. *)
let column name row = List.assoc name row

(* Add one to a key's count. find_opt returns None for a key never seen. *)
let bump table key =
  let n = Option.value (Hashtbl.find_opt table key) ~default:0 in
  Hashtbl.replace table key (n + 1)

let count_of table key = Option.value (Hashtbl.find_opt table key) ~default:0

let () =
  let rows = read_rows Sys.argv.(1) in
  let train = List.filter (fun row -> column "split" row = "train") rows in
  let test = List.filter (fun row -> column "split" row = "test") rows in
  (* label_counts: label -> rows. value_counts: (feature, value, label) ->
     rows. Hashtbl hashes and compares keys by value, so a tuple works as a
     key. seen: (feature, value) -> rows, used only for its distinct keys. *)
  let label_counts = Hashtbl.create 2 in
  let value_counts = Hashtbl.create 16 in
  let seen = Hashtbl.create 8 in
  List.iter
    (fun row ->
      bump label_counts (column "label" row);
      List.iter
        (fun f ->
          bump value_counts (f, column f row, column "label" row);
          bump seen (f, column f row))
        features)
    train;
  let distinct f =
    Hashtbl.fold (fun (g, _) _ n -> if g = f then n + 1 else n) seen 0
  in
  let n_train = float_of_int (List.length train) in
  (* Logs turn the product of probabilities into a sum, avoiding underflow.
     Add-one smoothing means an unseen value never gets probability zero. *)
  let log_score row label =
    let n_label = count_of label_counts label in
    List.fold_left
      (fun score f ->
        let count = count_of value_counts (f, column f row, label) + 1 in
        score +. log (float_of_int count /. float_of_int (n_label + distinct f)))
      (log (float_of_int n_label /. n_train))
      features
  in
  (* Hashtbl visits keys in no fixed order, so we sort the labels first. *)
  let labels =
    List.sort compare (Hashtbl.fold (fun label _ acc -> label :: acc) label_counts [])
  in
  (* Labels are tried in alphabetical order, and only a strictly higher score
     replaces the best, so an exact tie goes to the first. *)
  let classify row =
    let best, _ =
      List.fold_left
        (fun (best, best_score) label ->
          let score = log_score row label in
          if score > best_score then (label, score) else (best, best_score))
        ("", neg_infinity) labels
    in
    best
  in
  let correct = List.length (List.filter (fun row -> classify row = column "label" row) test) in
  Printf.printf "train_count %d\n" (List.length train);
  Printf.printf "test_count %d\n" (List.length test);
  Printf.printf "correct %d\n" correct;
  Printf.printf "accuracy %.6f\n"
    (float_of_int correct /. float_of_int (List.length test))

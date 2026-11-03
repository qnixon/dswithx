(* k-nearest neighbors classification, using only OCaml's standard library.

   Each test seed is labelled with the majority variety among its k nearest
   training seeds, by Euclidean distance. *)

let k = 5

(* A record type: each seed's measurements in millimetres and its variety. *)
type seed = { len : float; wid : float; variety : string }

(* Every row as (split, seed), with each column found by its header name. *)
let read_seeds path =
  In_channel.with_open_text path (fun ic ->
      let lines = In_channel.input_lines ic in
      let header = String.split_on_char ',' (List.hd lines) in
      let index name =
        match List.find_index (String.equal name) header with
        | Some i -> i
        | None -> failwith ("column not found: " ^ name)
      in
      List.map
        (fun line ->
          let fields = String.split_on_char ',' line in
          let field name = List.nth fields (index name) in
          ( field "split",
            { len = float_of_string (field "length_mm");
              wid = float_of_string (field "width_mm");
              variety = field "variety" } ))
        (List.tl lines))

let distance a b = sqrt (((a.len -. b.len) ** 2.) +. ((a.wid -. b.wid) ** 2.))

(* Sort the training seeds by distance and keep the first k. stable_sort
   keeps seeds at exactly equal distances in file order; the docs don't
   promise that for List.sort. *)
let nearest train point =
  let by_distance =
    List.stable_sort
      (fun a b -> Float.compare (distance point a) (distance point b))
      train
  in
  List.filteri (fun i _ -> i < k) by_distance

(* Count votes in an association list of (variety, count) pairs. A new
   variety goes on the end, so the list keeps first-seen order. *)
let rec add_vote label = function
  | [] -> [ (label, 1) ]
  | (l, n) :: rest when l = label -> (l, n + 1) :: rest
  | pair :: rest -> pair :: add_vote label rest

(* The variety with the most votes. > is strict, so on equal counts the
   variety seen first among the neighbors wins. *)
let majority labels =
  let counts = List.fold_left (fun acc l -> add_vote l acc) [] labels in
  let pick (bl, bn) (l, n) = if n > bn then (l, n) else (bl, bn) in
  fst (List.fold_left pick (List.hd counts) (List.tl counts))

let classify train point =
  majority (List.map (fun s -> s.variety) (nearest train point))

let () =
  let seeds = read_seeds Sys.argv.(1) in
  (* partition splits one list into the rows that pass a test and the rest *)
  let train, test = List.partition (fun (split, _) -> split = "train") seeds in
  let train = List.map snd train and test = List.map snd test in
  let correct =
    List.length (List.filter (fun s -> classify train s = s.variety) test)
  in
  Printf.printf "train_count %d\n" (List.length train);
  Printf.printf "test_count %d\n" (List.length test);
  Printf.printf "correct %d\n" correct;
  Printf.printf "accuracy %.6f\n"
    (float_of_int correct /. float_of_int (List.length test))

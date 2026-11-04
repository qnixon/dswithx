(* 5-fold cross-validation for k-nearest neighbors, using only OCaml's
   standard library.

   Splits the training seeds into 5 folds, scores each odd k from 1 to 15
   by holding out one fold at a time, picks the k with the best average
   accuracy, and then scores that k once on the untouched test seeds. *)

let folds = 5

(* Odd k only, so two varieties can't tie. *)
let ks = List.init 8 (fun i -> (2 * i) + 1)

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
let nearest k train point =
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

let classify k train point =
  majority (List.map (fun s -> s.variety) (nearest k train point))

let count_correct k train points =
  List.length (List.filter (fun s -> classify k train s = s.variety) points)

(* Fold f is rows f*size up to (f+1)*size. The rows are already shuffled,
   so consecutive blocks make fair folds. List.mapi numbers the rows, and
   List.partition splits them into the fold (i / size = f) and the rest. *)
let cv_accuracy train k =
  let size = List.length train / folds in
  let indexed = List.mapi (fun i s -> (i, s)) train in
  let correct =
    List.init folds (fun f ->
        let held_out, rest =
          List.partition (fun (i, _) -> i / size = f) indexed
        in
        count_correct k (List.map snd rest) (List.map snd held_out))
  in
  float_of_int (List.fold_left ( + ) 0 correct)
  /. float_of_int (List.length train)

let () =
  let seeds = read_seeds Sys.argv.(1) in
  (* partition splits one list into the rows that pass a test and the rest *)
  let train, test = List.partition (fun (split, _) -> split = "train") seeds in
  let train = List.map snd train and test = List.map snd test in
  Printf.printf "train_count %d\n" (List.length train);
  Printf.printf "test_count %d\n" (List.length test);
  (* A strictly better accuracy replaces the leader, so ties keep the
     smaller k. *)
  let best_k, _ =
    List.fold_left
      (fun (bk, ba) k ->
        let accuracy = cv_accuracy train k in
        Printf.printf "cv_accuracy_k%d %.6f\n" k accuracy;
        if accuracy > ba then (k, accuracy) else (bk, ba))
      (0, -1.) ks
  in
  (* Only now touch the test seeds, once, with the chosen k and all of
     train. *)
  let correct = count_correct best_k train test in
  Printf.printf "best_k %d\n" best_k;
  Printf.printf "test_correct %d\n" correct;
  Printf.printf "test_accuracy %.6f\n"
    (float_of_int correct /. float_of_int (List.length test))

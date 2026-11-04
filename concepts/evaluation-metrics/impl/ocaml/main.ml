(* Evaluation metrics for a binary classifier, using only OCaml's standard
   library.

   Reads each part's true label and the model's score, then reports the
   confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
   the accuracy of never flagging anything, and the area under the ROC
   curve. *)

(* Every part as (defective, score), with each column found by its header
   name. *)
let read_parts path =
  In_channel.with_open_text path (fun ic ->
      let lines = In_channel.input_lines ic in
      let header = String.split_on_char ',' (List.hd lines) in
      let index name =
        match List.find_index (String.equal name) header with
        | Some i -> i
        | None -> failwith ("column not found: " ^ name)
      in
      List.filter_map
        (fun line ->
          if line = "" then None
          else
            let fields = String.split_on_char ',' line in
            let field name = List.nth fields (index name) in
            Some (field "defective" = "1", float_of_string (field "score")))
        (List.tl lines))

(* OCaml never mixes int and float: float_of_int converts, and /. is float
   division. *)
let ratio a b = float_of_int a /. float_of_int b

let report parts suffix threshold =
  (* A part is flagged when its score reaches the threshold. *)
  let tp = ref 0 and fp = ref 0 and fn = ref 0 and tn = ref 0 in
  List.iter
    (fun (defective, score) ->
      let counter =
        match (score >= threshold, defective) with
        | true, true -> tp
        | true, false -> fp
        | false, true -> fn
        | false, false -> tn
      in
      incr counter)
    parts;
  let tp = !tp and fp = !fp and fn = !fn and tn = !tn in
  let accuracy = ratio (tp + tn) (List.length parts) in
  (* Of the flagged parts, how many are defective. *)
  let precision = ratio tp (tp + fp) in
  (* Of the defective parts, how many are flagged. *)
  let recall = ratio tp (tp + fn) in
  let f1 = 2. *. precision *. recall /. (precision +. recall) in
  Printf.printf "tp_at_%s %d\n" suffix tp;
  Printf.printf "fp_at_%s %d\n" suffix fp;
  Printf.printf "fn_at_%s %d\n" suffix fn;
  Printf.printf "tn_at_%s %d\n" suffix tn;
  Printf.printf "accuracy_at_%s %.6f\n" suffix accuracy;
  Printf.printf "precision_at_%s %.6f\n" suffix precision;
  Printf.printf "recall_at_%s %.6f\n" suffix recall;
  Printf.printf "f1_at_%s %.6f\n" suffix f1

(* The chance that a random defective part outscores a random good one.
   Compare every pair, scoring 2 for a win and 1 for a tie, so the count
   stays a whole number until the final division. *)
let auc parts =
  let scores wanted =
    List.filter_map (fun (d, s) -> if d = wanted then Some s else None) parts
  in
  let defective = scores true and good = scores false in
  let points = ref 0 in
  List.iter
    (fun d ->
      List.iter
        (fun g ->
          if d > g then points := !points + 2
          else if d = g then incr points)
        good)
    defective;
  ratio !points (2 * List.length defective * List.length good)

let () =
  let parts = read_parts Sys.argv.(1) in
  let n = List.length parts in
  let defective = List.length (List.filter fst parts) in
  Printf.printf "parts %d\n" n;
  Printf.printf "defective %d\n" defective;
  (* Never flagging anything is right about every good part. *)
  Printf.printf "baseline_accuracy %.6f\n" (ratio (n - defective) n);
  report parts "50" 0.5;
  report parts "30" 0.3;
  Printf.printf "auc %.6f\n" (auc parts)

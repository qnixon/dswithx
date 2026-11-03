(* Simple linear regression by least squares, using only OCaml's standard
   library.

   Fits score = intercept + slope * hours. The standard library has no
   regression, correlation, mean, or even sum, so every total is a fold and
   the formulas stay visible. *)

(* The header and the rows of a CSV file, each line split at its commas. *)
let read_csv path =
  In_channel.with_open_text path (fun ic ->
      match List.map (String.split_on_char ',') (In_channel.input_lines ic) with
      | header :: rows -> (header, rows)
      | [] -> failwith "empty file")

(* One column, found by its header name and read as floats. find_index
   returns an option: Some i, or None if the name is missing. *)
let column (header, rows) name =
  match List.find_index (String.equal name) header with
  | Some i -> List.map (fun fields -> float_of_string (List.nth fields i)) rows
  | None -> failwith ("column not found: " ^ name)

let sum values = List.fold_left ( +. ) 0. values

let () =
  let csv = read_csv Sys.argv.(1) in
  let xs = column csv "hours" and ys = column csv "score" in
  let n = float_of_int (List.length xs) in
  (* First pass: the means. *)
  let mean_x = sum xs /. n and mean_y = sum ys /. n in
  (* Second pass: deviations from the means. map2 walks both lists side by
     side, so each hours value meets the score on the same row. *)
  let sxx = sum (List.map (fun x -> (x -. mean_x) ** 2.) xs) in
  let syy = sum (List.map (fun y -> (y -. mean_y) ** 2.) ys) in
  let sxy = sum (List.map2 (fun x y -> (x -. mean_x) *. (y -. mean_y)) xs ys) in
  let slope = sxy /. sxx in
  let intercept = mean_y -. (slope *. mean_x) in
  let r = sxy /. sqrt (sxx *. syy) in
  Printf.printf "count %d\n" (List.length xs);
  List.iter
    (fun (name, value) -> Printf.printf "%s %.6f\n" name value)
    [ ("slope", slope); ("intercept", intercept); ("r", r); ("r_squared", r *. r) ]

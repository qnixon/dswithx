(* Descriptive statistics on one CSV column, using only OCaml's standard
   library.

   OCaml has no mean, median, or variance, so each is written out. Integers
   and floats never mix: floats have their own operators, +. -. *. /., and
   float_of_int converts a count before dividing. *)

let read_column path name =
  In_channel.with_open_text path (fun ic ->
      let lines = In_channel.input_lines ic in
      let header = String.split_on_char ',' (List.hd lines) in
      (* find_index returns an option: Some i, or None if it's missing *)
      let col =
        match List.find_index (String.equal name) header with
        | Some i -> i
        | None -> failwith ("column not found: " ^ name)
      in
      List.map
        (fun line -> float_of_string (List.nth (String.split_on_char ',' line) col))
        (List.tl lines))

let median sorted =
  let n = Array.length sorted in
  let mid = n / 2 in              (* / on two ints rounds toward zero *)
  if n mod 2 = 1 then sorted.(mid)
  else (sorted.(mid - 1) +. sorted.(mid)) /. 2.

let say name value = Printf.printf "%s %.6f\n" name value

let () =
  let values = Array.of_list (read_column Sys.argv.(1) "minutes") in
  Array.sort compare values;      (* sorts the array in place *)
  let n = Array.length values in
  let total = Array.fold_left ( +. ) 0. values in
  let mean = total /. float_of_int n in
  (* Sample variance divides by n - 1, not n (Bessel's correction). *)
  let sumsq = Array.fold_left (fun acc v -> acc +. ((v -. mean) ** 2.)) 0. values in
  let variance = sumsq /. float_of_int (n - 1) in
  let min = values.(0) and max = values.(n - 1) in
  Printf.printf "count %d\n" n;
  say "sum" total;
  say "mean" mean;
  say "median" (median values);
  say "min" min;
  say "max" max;
  say "range" (max -. min);
  say "variance" variance;
  say "std_dev" (sqrt variance)

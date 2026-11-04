(* Exact two-sided permutation test for a difference in means, using only
   OCaml's standard library.

   If compost made no difference, the "compost" and "control" labels are
   arbitrary, and any 8 of the 16 plants could have carried the compost
   label. We try every one of those splits and count how many give a
   difference at least as large as the one we observed. That fraction is
   the p-value. *)

(* Every row as (group, grams), with each column found by its header name. *)
let read_plants path =
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
            Some (field "group", int_of_string (field "grams")))
        (List.tl lines))

let sum = List.fold_left ( + ) 0

(* Call visit with the total of every way to choose k of the plants from
   position i onward. Each plant is either chosen (add it, and choose k - 1
   from the rest) or not (choose all k from the rest). *)
let rec each_chosen_total plants i k total visit =
  if k = 0 then visit total
  else if Array.length plants - i >= k then begin
    each_chosen_total plants (i + 1) (k - 1) (total + plants.(i)) visit;
    each_chosen_total plants (i + 1) k total visit
  end

let () =
  let rows = read_plants Sys.argv.(1) in
  let group name = List.filter_map (fun (g, x) -> if g = name then Some x else None) rows in
  let control = group "control" and compost = group "compost" in
  let n = List.length compost in
  let plants = Array.of_list (control @ compost) in
  let total = sum control + sum compost in
  (* Both groups have n plants, so comparing totals is the same as comparing
     means, and int totals stay whole numbers: no floating-point near-ties. *)
  let observed = sum compost - sum control in
  (* ref makes a mutable cell; ! reads it and := sets it. *)
  let splits = ref 0 and as_extreme = ref 0 in
  each_chosen_total plants 0 n 0 (fun chosen ->
      let difference = chosen - (total - chosen) in
      incr splits;
      (* Two-sided: a difference counts in either direction. *)
      if abs difference >= abs observed then incr as_extreme);
  let mean xs = float_of_int (sum xs) /. float_of_int (List.length xs) in
  Printf.printf "control_count %d\n" (List.length control);
  Printf.printf "compost_count %d\n" n;
  Printf.printf "control_mean %.6f\n" (mean control);
  Printf.printf "compost_mean %.6f\n" (mean compost);
  Printf.printf "observed_difference %.6f\n"
    (float_of_int observed /. float_of_int n);
  Printf.printf "splits %d\n" !splits;
  Printf.printf "as_extreme %d\n" !as_extreme;
  Printf.printf "p_value %.6f\n"
    (float_of_int !as_extreme /. float_of_int !splits)

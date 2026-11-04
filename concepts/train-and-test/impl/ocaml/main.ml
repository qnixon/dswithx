(* Train and test error for polynomials of degree 1 to 8, using only
   OCaml's standard library.

   Each polynomial is fitted by least squares to the training drives only:
   we build the normal equations and solve them by Gaussian elimination.
   Then we measure its root-mean-square error on the training drives and on
   the test drives it never saw. A matrix is an array of row arrays, so
   m.(i).(j) is row i, column j, counting from 0. *)

let max_degree = 8

(* Every drive as (split, speed, litres), with each column found by its
   header name. *)
let read_drives path =
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
            Some
              ( field "split",
                float_of_string (field "speed"),
                float_of_string (field "litres") ))
        (List.tl lines))

(* Solve a x = b by Gaussian elimination with partial pivoting. *)
let solve a b =
  let n = Array.length b in
  (* The augmented matrix: each row of a with its entry of b on the end. *)
  let m = Array.init n (fun i -> Array.append a.(i) [| b.(i) |]) in
  for col = 0 to n - 1 do
    (* Swap up the row with the largest entry in this column, which keeps
       the rounding error small. Swapping two rows just swaps the two row
       arrays in m. *)
    let pivot = ref col in
    for r = col + 1 to n - 1 do
      if Float.abs m.(r).(col) > Float.abs m.(!pivot).(col) then pivot := r
    done;
    let top = m.(col) in
    m.(col) <- m.(!pivot);
    m.(!pivot) <- top;
    for r = col + 1 to n - 1 do
      let factor = m.(r).(col) /. m.(col).(col) in
      for c = col to n do
        m.(r).(c) <- m.(r).(c) -. (factor *. m.(col).(c))
      done
    done
  done;
  (* Back substitution, from the last unknown up. *)
  let x = Array.make n 0. in
  for r = n - 1 downto 0 do
    let known = ref 0. in
    for c = r + 1 to n - 1 do
      known := !known +. (m.(r).(c) *. x.(c))
    done;
    x.(r) <- (m.(r).(n) -. !known) /. m.(r).(r)
  done;
  x

(* z to a whole-number power. ** takes two floats, so the power converts. *)
let power z i = z ** float_of_int i

(* Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i of
   Z is 1, z_i, z_i^2, ..., z_i^degree. points holds (z, y) pairs. *)
let fit points degree =
  let size = degree + 1 in
  let a = Array.make_matrix size size 0. and b = Array.make size 0. in
  List.iter
    (fun (z, y) ->
      for i = 0 to degree do
        b.(i) <- b.(i) +. (y *. power z i);
        for j = 0 to degree do
          a.(i).(j) <- a.(i).(j) +. power z (i + j)
        done
      done)
    points;
  solve a b

let rmse coefs points =
  let predict z = Array.fold_left ( +. ) 0. (Array.mapi (fun i c -> c *. power z i) coefs) in
  let total = List.fold_left (fun acc (z, y) -> acc +. ((predict z -. y) ** 2.)) 0. points in
  sqrt (total /. float_of_int (List.length points))

let () =
  let drives = read_drives Sys.argv.(1) in
  let part name =
    List.filter_map (fun (s, x, y) -> if s = name then Some (x, y) else None) drives
  in
  let train = part "train" and test = part "test" in
  (* Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
     largest entry at degree 8) would swamp the small ones and make the
     equations hard to solve accurately. *)
  let speeds = List.map fst train in
  let low = List.fold_left Float.min infinity speeds in
  let high = List.fold_left Float.max neg_infinity speeds in
  let mid = (low +. high) /. 2. and half = (high -. low) /. 2. in
  let scaled points = List.map (fun (x, y) -> ((x -. mid) /. half, y)) points in
  let train_z = scaled train and test_z = scaled test in
  Printf.printf "train_count %d\n" (List.length train);
  Printf.printf "test_count %d\n" (List.length test);
  let fits = List.init max_degree (fun i -> (i + 1, fit train_z (i + 1))) in
  List.iter (fun (d, c) -> Printf.printf "train_rmse_d%d %.6f\n" d (rmse c train_z)) fits;
  List.iter (fun (d, c) -> Printf.printf "test_rmse_d%d %.6f\n" d (rmse c test_z)) fits

(* Principal component analysis by power iteration, using only OCaml's
   standard library.

   Standardizes the four scores, builds their correlation matrix, and finds
   the top two eigenvectors (the principal components): power iteration
   finds the first, then deflation removes it from the matrix so the same
   steps find the second. A matrix is an array of row arrays, so m.(i).(j)
   is row i, column j, counting from 0. *)

let subjects = [| "math"; "physics"; "reading"; "writing" |]
let steps = 1000

(* The named columns of every row, read as floats, in the order asked for. *)
let read_rows path =
  In_channel.with_open_text path (fun ic ->
      let lines = In_channel.input_lines ic in
      let header = String.split_on_char ',' (List.hd lines) in
      let col name =
        match List.find_index (String.equal name) header with
        | Some i -> i
        | None -> failwith ("column not found: " ^ name)
      in
      let indexes = Array.map col subjects in
      Array.of_list
        (List.map
           (fun line ->
             let f = Array.of_list (String.split_on_char ',' line) in
             Array.map (fun i -> float_of_string f.(i)) indexes)
           (List.tl lines)))

let dot u v = Array.fold_left ( +. ) 0. (Array.map2 ( *. ) u v)

(* A matrix times a vector: each row of the matrix dotted with the vector. *)
let mat_vec m v = Array.map (fun row -> dot row v) m

let normalize v =
  let length = sqrt (dot v v) in
  Array.map (fun x -> x /. length) v

(* Power iteration: multiply by the matrix and rescale, 1,000 times.
   Returns the pair (eigenvalue, eigenvector). *)
let top_eigenvector m =
  let v = ref (Array.init (Array.length m) (fun i -> if i = 0 then 1. else 0.)) in
  for _ = 1 to steps do
    v := normalize (mat_vec m !v)   (* ! reads a ref, := replaces its value *)
  done;
  (* An eigenvector can point either way; make its first entry positive. *)
  let v = if !v.(0) < 0. then Array.map Float.neg !v else !v in
  (dot v (mat_vec m v), v)

let () =
  let rows = read_rows Sys.argv.(1) in
  let n = Array.length rows and k = Array.length subjects in
  let count = float_of_int n in
  (* Standardize each column to mean 0 and (sample) standard deviation 1. *)
  let column j = Array.map (fun r -> r.(j)) rows in
  let means = Array.init k (fun j -> Array.fold_left ( +. ) 0. (column j) /. count) in
  let sds =
    Array.init k (fun j ->
        let sumsq = Array.fold_left (fun acc x -> acc +. ((x -. means.(j)) ** 2.)) 0. (column j) in
        sqrt (sumsq /. (count -. 1.)))
  in
  let z = Array.map (Array.mapi (fun j x -> (x -. means.(j)) /. sds.(j))) rows in
  (* The correlation matrix: the covariance of the standardized columns. *)
  let zcol j = Array.map (fun r -> r.(j)) z in
  let corr = Array.init k (fun i -> Array.init k (fun j -> dot (zcol i) (zcol j) /. (count -. 1.))) in
  let value_1, pc_1 = top_eigenvector corr in
  (* Deflation: subtract the first component's share, leaving the rest. *)
  let deflated =
    Array.mapi (fun i row -> Array.mapi (fun j c -> c -. (value_1 *. pc_1.(i) *. pc_1.(j))) row) corr
  in
  let value_2, pc_2 = top_eigenvector deflated in
  Printf.printf "count %d\n" n;
  List.iteri
    (fun i (value, pc) ->
      let c = i + 1 in
      Printf.printf "eigenvalue_%d %.6f\n" c value;
      (* Standardized columns each have variance 1, so the total is k. *)
      Printf.printf "explained_%d %.6f\n" c (value /. float_of_int k);
      Array.iteri (fun j subject -> Printf.printf "pc%d_%s %.6f\n" c subject pc.(j)) subjects)
    [ (value_1, pc_1); (value_2, pc_2) ];
  Printf.printf "student_1_pc1 %.6f\n" (dot z.(0) pc_1);
  Printf.printf "student_1_pc2 %.6f\n" (dot z.(0) pc_2)

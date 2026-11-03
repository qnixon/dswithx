(* k-means clustering (Lloyd's algorithm), using only OCaml's standard
   library.

   Starts from the first k points as centroids, then alternates two steps
   until no point changes cluster: assign each point to its nearest centroid,
   and move each centroid to the mean of its points. The repetition is a
   function that calls itself, the usual way to loop in OCaml. *)

(* A record with named fields; p.x reads one. *)
type point = { x : float; y : float }

let k = 3
let max_iterations = 100

(* The x and y columns as an array of points. The header gives their
   positions. *)
let read_points path =
  In_channel.with_open_text path (fun ic ->
      match In_channel.input_lines ic with
      | [] -> failwith "empty file"
      | header :: rows ->
          let names = String.split_on_char ',' header in
          let index name =
            match List.find_index (String.equal name) names with
            | Some i -> i
            | None -> failwith ("column not found: " ^ name)
          in
          let xi = index "x" and yi = index "y" in
          rows
          |> List.filter (fun row -> row <> "")
          |> List.map (fun row ->
                 let fields = String.split_on_char ',' row in
                 { x = float_of_string (List.nth fields xi);
                   y = float_of_string (List.nth fields yi) })
          |> Array.of_list)

(* Squared Euclidean distance. It ranks centroids in the same order as the
   distance itself, so finding the nearest one needs no sqrt. *)
let squared_distance a b = ((a.x -. b.x) ** 2.) +. ((a.y -. b.y) ** 2.)

(* The index of the closest centroid. Only a strictly smaller distance
   replaces the best, so a tie goes to the lower index. *)
let nearest centroids p =
  let best = ref 0 in   (* ref makes a mutable cell: !best reads, := writes *)
  Array.iteri
    (fun j c ->
      if squared_distance p c < squared_distance p centroids.(!best) then best := j)
    centroids;
  !best

(* Move each centroid to the mean of its points. An empty cluster keeps its
   old centroid. *)
let update points assignment centroids =
  Array.mapi
    (fun j c ->
      let sum_x = ref 0. and sum_y = ref 0. and count = ref 0 in
      Array.iteri
        (fun i p ->
          if assignment.(i) = j then begin
            sum_x := !sum_x +. p.x;
            sum_y := !sum_y +. p.y;
            incr count
          end)
        points;
      if !count = 0 then c
      else
        let n = float_of_int !count in
        { x = !sum_x /. n; y = !sum_y /. n })
    centroids

(* One assignment step, then either stop or update and go again. previous is
   an option: None before the first pass, so the first comparison always
   counts as a change. = compares two arrays element by element. Returns the
   number of assignment steps, the final assignment, and the centroids. *)
let rec run points iterations previous centroids =
  let step = iterations + 1 in
  let assignment = Array.map (nearest centroids) points in
  if previous = Some assignment then (step, assignment, centroids)
  else
    let moved = update points assignment centroids in
    if step = max_iterations then (step, assignment, moved)
    else run points step (Some assignment) moved

let () =
  let points = read_points Sys.argv.(1) in
  let iterations, assignment, centroids =
    run points 0 None (Array.sub points 0 k)
  in
  Printf.printf "iterations %d\n" iterations;
  (* Clusters are numbered from 0 inside the program and from 1 in the output. *)
  Array.iteri
    (fun j c -> Printf.printf "centroid_%d_x %.6f\ncentroid_%d_y %.6f\n" (j + 1) c.x (j + 1) c.y)
    centroids;
  for j = 0 to k - 1 do
    let size = Array.fold_left (fun n a -> if a = j then n + 1 else n) 0 assignment in
    Printf.printf "size_%d %d\n" (j + 1) size
  done;
  let inertia = ref 0. in
  Array.iteri
    (fun i p -> inertia := !inertia +. squared_distance p centroids.(assignment.(i)))
    points;
  Printf.printf "inertia %.6f\n" !inertia

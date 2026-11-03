(* Logistic regression by gradient descent, using only OCaml's standard
   library.

   Predicts whether a student passed from study hours and sleep. Each
   feature is rescaled with the training rows' mean and standard deviation,
   then the weights start at zero and take 1,000 steps of batch gradient
   descent on the average log-loss. The weights are an array, and each step
   builds a new array from the old one. *)

let learning_rate = 0.5
let steps = 1000

(* Each row becomes ([| hours; sleep |], passed, split). *)
let read_rows path =
  In_channel.with_open_text path (fun ic ->
      let lines = In_channel.input_lines ic in
      let header = String.split_on_char ',' (List.hd lines) in
      let col name =
        match List.find_index (String.equal name) header with
        | Some i -> i
        | None -> failwith ("column not found: " ^ name)
      in
      let hours = col "hours" and sleep = col "sleep" in
      let passed = col "passed" and split = col "split" in
      List.map
        (fun line ->
          let f = Array.of_list (String.split_on_char ',' line) in
          ( [| float_of_string f.(hours); float_of_string f.(sleep) |],
            float_of_string f.(passed),
            f.(split) ))
        (List.tl lines))

let sigmoid z = 1. /. (1. +. exp (-.z))

(* Array.fold_left and Array.map2 walk two arrays side by side. *)
let dot u v = Array.fold_left ( +. ) 0. (Array.map2 ( *. ) u v)

let mean xs = Array.fold_left ( +. ) 0. xs /. float_of_int (Array.length xs)

(* Sample standard deviation: divide by n - 1. *)
let sd xs =
  let m = mean xs in
  let sumsq = Array.fold_left (fun acc x -> acc +. ((x -. m) ** 2.)) 0. xs in
  sqrt (sumsq /. float_of_int (Array.length xs - 1))

(* One step of gradient descent. The gradient for weight j is the mean of
   (p - y) times input j, summed over every student before any weight
   moves, so the old array is never changed. *)
let step xs ys weights =
  let n = float_of_int (Array.length xs) in
  let errors = Array.map2 (fun x y -> sigmoid (dot weights x) -. y) xs ys in
  Array.mapi
    (fun j w ->
      let column = Array.map (fun x -> x.(j)) xs in
      w -. (learning_rate *. dot errors column /. n))
    weights

let () =
  let rows = read_rows Sys.argv.(1) in
  (* partition splits one list into the rows that pass a test and the rest. *)
  let train, test = List.partition (fun (_, _, split) -> split = "train") rows in
  let train = Array.of_list train in
  let features = Array.map (fun (x, _, _) -> x) train in
  let ys = Array.map (fun (_, y, _) -> y) train in
  (* Scale with the training rows only. The leading 1 multiplies the intercept. *)
  let columns = Array.init 2 (fun j -> Array.map (fun x -> x.(j)) features) in
  let means = Array.map mean columns and sds = Array.map sd columns in
  let scale x =
    Array.append [| 1. |] (Array.mapi (fun j v -> (v -. means.(j)) /. sds.(j)) x)
  in
  let xs = Array.map scale features in
  (* let rec lets descend call itself: it takes one step, then counts the
     remaining steps down until none are left. *)
  let rec descend weights k = if k = 0 then weights else descend (step xs ys weights) (k - 1) in
  let weights = descend [| 0.; 0.; 0. |] steps in
  let n = Array.length xs in
  let log_loss =
    -.Array.fold_left ( +. ) 0.
        (Array.map2
           (fun x y ->
             let p = sigmoid (dot weights x) in
             (y *. log p) +. ((1. -. y) *. log (1. -. p)))
           xs ys)
    /. float_of_int n
  in
  let predict x = if sigmoid (dot weights (scale x)) >= 0.5 then 1. else 0. in
  let correct = List.length (List.filter (fun (x, y, _) -> predict x = y) test) in
  let test_count = List.length test in
  Printf.printf "train_count %d\n" n;
  Printf.printf "test_count %d\n" test_count;
  Printf.printf "intercept %.6f\n" weights.(0);
  Printf.printf "weight_hours %.6f\n" weights.(1);
  Printf.printf "weight_sleep %.6f\n" weights.(2);
  Printf.printf "log_loss %.6f\n" log_loss;
  Printf.printf "correct %d\n" correct;
  Printf.printf "accuracy %.6f\n" (float_of_int correct /. float_of_int test_count)

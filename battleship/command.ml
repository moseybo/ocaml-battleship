type entry_phrase = string list
type command = Fire of entry_phrase | Quit | Status | Place of entry_phrase 
             | Versus | Solo | PlaceRandom | Bomb of entry_phrase
exception Empty 
exception Malformed 

(** [shave entry acc] is entry with all "" elements removed. These elements
    appear as a result of the String.split_on_char function. *)
let rec shave (entry:entry_phrase) (acc:entry_phrase) : entry_phrase = 
  match entry with 
  | [] -> List.rev acc
  | h::t -> if (h="") then shave t acc else shave t (h::acc)

(** [parseHelper entry] is the command corresponding to the given entry phrase. *)
let parseHelper (entry:entry_phrase) : command = 
  match entry with 
  | [] -> raise Empty
  | h::t -> match h with
    | "fire"  -> if t=[] then raise Malformed else Fire t
    | "quit"  -> if t=[] then Quit else raise Malformed 
    | "status" -> if t=[] then Status else raise Malformed
    | "random" -> if t=[] then PlaceRandom else raise Malformed
    | "place" -> if t=[] then raise Malformed else Place t
    | "versus" -> if t=[] then Versus else raise Malformed
    | "solo" -> if t=[] then Solo else raise Malformed
    | "bomb" -> if t=[] then raise Malformed else Bomb t
    | _ -> raise Malformed

(** [parse] is the command corresponding to the given string of user input. *)
let parse string = 
  let entry = String.split_on_char ' ' string in 
  parseHelper (shave entry [])

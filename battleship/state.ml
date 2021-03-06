open Battleship

(**  An instance of a battleship game. *)
type state = {ship_list: ship list; current_grid: grid; sunk_list: ship list; 
              ships_on_grid: ship list; bombs_left: int}

(**  [init_battleship] is a new battleship *)
let init_battleship = {name = Battleship; size = 4; hits = 0}

(**  [init_cruiser] is a new cruiser *)
let init_cruiser = {name = Cruiser; size = 3; hits = 0}

(**  [init_submarine] is a new submarine *)
let init_submarine = {name = Submarine; size = 3; hits = 0}

(**  [init_destroyer] is a new destroyer *)
let init_destroyer = {name = Destroyer; size = 2; hits = 0}

(**  [init_carrier] is a new carrier *)
let init_carrier = {name = Carrier; size = 2; hits = 0}

(**  [init_ships] is a list containing one of each type of ship, with hits 
     set to 0. *)
let init_ships = 
  [{name = Battleship; size = 4; hits = 0}; {name = Cruiser; size = 3; hits = 0}; 
   {name = Submarine; size = 3; hits = 0}; {name = Destroyer; size = 2; hits = 0};
   {name = Carrier; size = 2; hits = 0}] 

(** [init_state] is a new state, i.e. a new battleship game. *)
let init_state : state = {ship_list = init_ships; 
                          current_grid = Battleship.init_grid Battleship.rows 
                              Battleship.columns [];
                          sunk_list = [];
                          ships_on_grid = []; bombs_left = 3}

(** OutOfBounds is raised when the given coordinates are outside of the grid 
    or do not correspond to ship size. *)
exception OutOfBounds 

(** NotRight is raised when the given coordinates could not possibly make a  
    ship because they are neither part of the same column nor the same row. *)
exception NotRight

(** [place ship coordOne coordTwo state] is the new state of the game when 
    [ship] is placed in the grid given by [state]. 
    Raises: NotRight is coordinates are incompatible. 
            OutOfBounds if coordinates are outside of the grid. *)

let place (ship:ship) (coordOne:coordinate) (coordTwo:coordinate) 
    (state:state) = 
  if (fst(coordOne) > 'j' || snd(coordOne) > 10) || 
     (fst(coordTwo) > 'j' || snd(coordTwo) > 10) then raise OutOfBounds 

  else if not ((fst coordOne = fst coordTwo) || (snd coordOne = snd coordTwo)
               || (fst coordOne = fst coordTwo && snd coordOne = snd coordTwo)) 
  then raise NotRight
  else if (snd coordOne = snd coordTwo && 
           Pervasives.abs (Char.code (fst coordOne) 
                           - Char.code(fst coordTwo)) = ship.size - 1 ) 
  then 
    let coords = Battleship.make_new_char_list rows (snd coordOne) 
        (fst coordOne) (fst coordTwo) [] in 
    {ship_list=init_ships; current_grid = Battleship.make_grid ship coords 
                               state.current_grid [];
     sunk_list=[]; ships_on_grid=ship::state.ships_on_grid; bombs_left=3}
  else if (fst coordOne = fst coordTwo && Pervasives.abs 
             (snd coordOne - snd coordTwo) = ship.size - 1)
  then
    let coords = Battleship.make_new_int_list (fst coordOne) columns
        (snd coordOne) (snd coordTwo) [] in 
    {ship_list=init_ships; current_grid = Battleship.make_grid ship coords 
                               state.current_grid [];
     sunk_list=[]; ships_on_grid=ship::state.ships_on_grid; bombs_left=3}
  else raise OutOfBounds

(** [new_ship_list ship ship_list outlist] is the list of ships resulting from 
    finding [ship] in [ship_list] and incrementing its hit count.  *)
let rec new_ship_list ship ship_list outlist : ship list= 
  match ship_list with 
  | [] -> outlist
  | {name=nm;size=sz;hits=hts}::t when nm=ship.name -> 
    new_ship_list ship t ({name=ship.name;
                           size=ship.size; hits=hts+1}::outlist)
  | h::t -> new_ship_list ship t (h::outlist)

(** [sink_ship ship currentGrid outlist] is the grid that has located [ship] 
    and changed every point representing [ship] to the Sunk status. *)
let rec sink_ship ship (currentGrid:Battleship.grid) outlist = 
  match currentGrid with 
  |[] -> outlist 
  |((r,c),Hit({name=nm;size=sz;hits=hts}))::t when ship.name = nm -> 
    sink_ship ship t (((r,c),Sunk(ship))::outlist) 
  |((r,c),s)::t -> sink_ship ship t (((r,c),s)::outlist)
let rec hit_ship ship (currentGrid:Battleship.grid) r' c' outlist : Battleship.grid = 
  match currentGrid with 
  |[] -> outlist 
  |((r,c),Occupied({name=nm;size=sz;hits=hts}))::t when 
      (ship.name = nm && (r'<>r || c'<>c)) ->
    hit_ship ship t r' c' (((r,c),Occupied({ship with hits=hts+1}))::outlist)
  |((r,c),Occupied({name=nm;size=sz;hits=hts}))::t when 
      (ship.name = nm && r'=r && c'=c) ->
    hit_ship ship t r' c' (((r,c),Hit({ship with hits=hts+1}))::outlist)
  |((r,c),Hit({name=nm;size=sz;hits=hts}))::t when ship.name = nm -> 
    hit_ship ship t r' c' (((r,c),Hit({ship with hits=ship.hits+1}))::outlist)
  |((r,c),s)::t -> hit_ship ship t r' c' (((r,c),s)::outlist)

let update_grid_occupied ship coord state (currentGrid:Battleship.grid) 
    outlist = 
  let new_grid = 
    (hit_ship ship state.current_grid (fst coord) (snd coord) []) in
  if ship.hits+1 = ship.size then
    sink_ship ship new_grid []
  else new_grid

(** [upgrade_grid_empty coord currentGrid outlist] is [currentGrid]
    with the point at the given coordinate changed from Empty status to 
    Miss status. *)
let rec update_grid_empty coord (currentGrid:Battleship.grid) outlist =
  match currentGrid with
  | [] -> outlist
  | ((r,c),s)::t  -> if (r,c) = coord then (((r,c),Miss)::outlist) @ t
    else update_grid_empty coord t (((r,c),s)::outlist)

(** [is_sunk ship] is whether or not [ship] is of Sunk status. *)
let is_sunk ship : bool =
  if ship.hits>=ship.size then  true else false

(** [curr_sunk_list currShipList outlist] is the list of ships that have sunk in
    the current game.*)
let rec curr_sunk_list currShipList outlist = 
  match currShipList with 
  | [] -> outlist 
  | h::t -> if (is_sunk h) then curr_sunk_list t (h::outlist) 
    else curr_sunk_list t outlist

(** [fire coord currentState] is the new game state resulting from firing at 
     the given coordinate. *)
let fire (coord: coordinate) (currentState: state) =
  let rec fireHelper coord currGrid currShipList= 
    match currGrid with 
    | [] ->  {ship_list = currShipList; current_grid = currGrid; 
              sunk_list = curr_sunk_list currShipList [];
              ships_on_grid = currentState.ships_on_grid; 
              bombs_left=currentState.bombs_left}
    | ((r,c),Empty)::t when (r,c) = coord -> 
      let update_grid_var = update_grid_empty coord currGrid [] in 
      {ship_list=currShipList; current_grid=update_grid_var;
       sunk_list = currentState.sunk_list;
       ships_on_grid = currentState.ships_on_grid; 
       bombs_left=currentState.bombs_left}
    | ((r,c),Hit(s))::t when (r,c)=coord -> 
      {ship_list = currShipList; current_grid = currGrid; 
       sunk_list = curr_sunk_list currShipList [];
       ships_on_grid = currentState.ships_on_grid;
       bombs_left=currentState.bombs_left}
    | ((r,c),Miss)::t when (r,c)=coord -> 
      {ship_list = currShipList; current_grid = currGrid; 
       sunk_list = curr_sunk_list currShipList [];
       ships_on_grid = currentState.ships_on_grid;
       bombs_left=currentState.bombs_left}
    | ((r,c),Occupied(s))::t when (r,c)=coord -> 
      let update_ship_list = new_ship_list s currShipList [] in 
      let update_grid_var = 
        update_grid_occupied s coord currentState currGrid [] in 
      {ship_list=update_ship_list; current_grid=update_grid_var;
       sunk_list = curr_sunk_list update_ship_list [];
       ships_on_grid = currentState.ships_on_grid; 
       bombs_left=currentState.bombs_left}
    | ((r,c),point)::t -> let new_state = fireHelper coord t currShipList in 
      if List.length new_state.current_grid < 100 then
        let new_grid = ((r,c),point)::new_state.current_grid in 
        { new_state with current_grid = new_grid}
      else new_state
  in fireHelper coord currentState.current_grid currentState.ship_list 

(** [placing] is whether or not the current game is still in placing mode. 
    i.e. have all the ships been placed? *)
let placing currentState : bool = 
  if List.length currentState.ships_on_grid <> 5 then true else false

(** [string_of_ships] is a string of the names of each type of ship. *)
let string_of_ships ship = 
  match ship.name with 
  | Carrier -> "Carrier"
  | Battleship -> "Battleship"
  | Cruiser -> "Cruiser"
  | Submarine -> "Submarine"
  | Destroyer -> "Destroyer"

(** [queue_helper currentState initships outlist] is the list of ships that 
    still need to be placed. *)
let rec queue_helper currentState initships outlist : ship list = 
  let curr_ships_on_grid = currentState.ships_on_grid in 
  match initships with 
  | [] -> outlist 
  | h::t -> if List.mem h curr_ships_on_grid then queue_helper currentState t outlist 
    else queue_helper currentState t (h::outlist)

(** [queue currentState] is a well formatted, pretty string of the list of ships 
    that still need to be placed. *)
let queue currentState = 
  let ships_left = queue_helper currentState init_ships [] in 
  let ship_name ship = string_of_ships ship in 
  let concat a b = 
    if a="" then b else (a ^ ", " ^ b) in
  let ships_left_names = List.map ship_name ships_left in
  List.fold_left concat "" ships_left_names

(** [getAmountSunk] is the number of ships that have sunk in the current game. *)
let rec getAmountSunk lst accum = 
  match lst with
  | [] -> accum
  | h::t -> getAmountSunk t (accum + 1) 

(** [generate_0_1 ()] generates a random int from 0-1 inclusive. *)
let generate_0_1 () = 
  Random.int 2

(** [generate_0_3 ()] generates a random int from 0-3 inclusive. *)
let generate_0_3 () = 
  Random.int 4

(** [generate_rnd_row ()] is a random char representing a row. *)
let generate_rnd_row () = 
  List.nth (Battleship.rows) (Random.int 10) 

(** [generate_rnd_row ()] is a random int representing a column. *)
let generate_rnd_col () = 
  List.nth (Battleship.columns) (Random.int 10)

(** [int_choice elt1 elt2] is either [elt1] or [elt2] with random chance. *)
let int_choice elt1 elt2 = 
  if (elt1 > 11 || elt1 < 1) && not (elt2 > 11 || elt2 < 1) then elt2 
  else if (elt2 > 11 || elt2 < 1) && not (elt1 > 11 || elt1 < 1) then elt1 
  else if generate_0_1 () = 1 then elt1 
  else elt2

(** [char_choice elt1 elt2] is either [elt1] or [elt2] with random chance. *)
let char_choice  elt1 elt2 = 
  if ('a' <= elt1 && elt1 <= 'j') && not ('a' <= elt2 && elt2 <= 'j') then elt1 
  else if ('a' <= elt2 && elt2 <= 'j') && not ('a' <= elt1 && elt1 <= 'j') 
  then elt2 
  else if generate_0_1 () = 1 then elt1 
  else elt2

(** [make_AI_coords decider row col rowcode ship] is a horizontal or vertical 
    set of coordinates. Wether or not it is horizontal depends on [decider]. *) 
let make_AI_coords decider (row: char) col rowcode (ship:Battleship.ship) = 
  if decider = 0 then 
    ( (row,col), 
      (row,  (int_choice (col - ship.size + 1) (col + ship.size - 1))))  
  else 
    ( (row,col), (char_choice (Char.chr (rowcode - ship.size + 1 )) 
                    (Char.chr (rowcode + ship.size - 1)),col)  )

(** [sort_tuple tup] is a sorted version of [tup]. *)
let sort_tuple tup = 
  match tup with 
  |((r1, c1), (r2, c2)) -> if c2 > c1 || r2 > r1 then ((r1, c1), (r2, c2)) 
    else ((r2, c2), (r1, c1))

(** [output_AI_coords ship] is a tuple with two coordinates denoting where the 
    given ship will be placed. Note: This placement is random as there is 
    clearly no user input. *)
let output_AI_coords ship =
  let rnd_0_1 = generate_0_1 () in
  let c = generate_rnd_col () in
  let r = generate_rnd_row () in 
  let r_code = Char.code r in 
  let unsorted_tuple = make_AI_coords rnd_0_1 r c r_code ship in 
  sort_tuple unsorted_tuple

(** [state_builder_AI currState ships] is the state resulting from randomly 
    placing every ship in [ships] onto [currState].current_grid. *)
let rec state_builder_AI (currState:state) (ships:ship list) =
  match ships with
  | [] -> currState
  | ship::t -> 
    try 
      let coords = (output_AI_coords ship) in 
      let new_state = (place ship (fst coords) (snd coords) currState) in
      if List.length new_state.ships_on_grid = 
         List.length currState.ships_on_grid
      then state_builder_AI currState ships
      else state_builder_AI new_state t
    with 
    | _ -> state_builder_AI currState ships

(** [can_fire point] is whether or not this point can be fired at. *)
let can_fire (point:Battleship.point) = 
  match point with 
  | ((r,c), Hit(s)) -> false
  |((r,c), Sunk(s)) -> false 
  |((r,c), Miss) -> false 
  |_ -> true 

(** [get_point coord grid fullgrid] is the point object associated with the 
    given [coord]. The object exists on the current grid, [fullgrid]. *)
let rec get_point (coord:Battleship.coordinate) (grid: Battleship.grid) 
    (fullgrid:Battleship.grid)= 
  match grid with 
  |[] -> failwith"coord does not exist in grid"
  |h::t -> if fst(h) = coord then h else get_point coord t fullgrid

(** [find_other_hit_coord grid stalepoint_list fullgrid] is a coordinate which 
    corresponds to a ship of status Hit. This is a helper to the AI's logic.*)
let rec find_other_hit_coord (grid:Battleship.grid) 
    (stalepoint_list:Battleship.coordinate list) (fullgrid:Battleship.grid)=
  match grid with 
  |[] -> Random.init (int_of_float ((Unix.time ())) mod 10000);
    let coords = (generate_rnd_row (), generate_rnd_col ()) in
    if can_fire(get_point coords fullgrid fullgrid) 
    then coords 
    else find_other_hit_coord [] stalepoint_list  fullgrid 
  |((r,c), Hit(s))::t when not(List.mem (r,c) stalepoint_list) -> (r,c)
  |h::t -> find_other_hit_coord t stalepoint_list fullgrid

(** [is_hit point] is whether or not [point] is of Hit status. *)
let is_hit (point:Battleship.point) = 
  match point with 
  | ((r,c), Hit(s)) -> true
  |_ -> false

(** [pick_adjacent grid point rowcode stale_list time] is a point near [point] 
    that can be fired at. Note: "near" means as close as possible. *)
let rec pick_adjacent grid (point:Battleship.point) (rowcode: int) stale_list 
    time : Battleship.coordinate = 
  if time -. (Unix.time ()) > 3.0  
  then (generate_rnd_row (), generate_rnd_col ()) 
  else 
    (*if square above is hit, shoot below *)
  if 'a' <= (Char.chr (rowcode - 1)) 
  && (Char.chr (rowcode - 1)) <= 'j' && 1 <= (snd (fst point)) 
  && (snd (fst point))<= 10 && 'a' <= (Char.chr (rowcode + 1)) && 
  (Char.chr (rowcode + 1)) <= 'j' && 1 <= (snd (fst point)) && 
  (snd (fst point))<= 10 &&
  is_hit (get_point (Char.chr (rowcode - 1) , snd (fst point)) grid grid) 
  && can_fire (get_point (Char.chr (rowcode + 1) , snd (fst point)) grid grid)
  then (Char.chr (rowcode + 1) , snd (fst point)) 
  (*if square  below is hit, shoot above *)
  else if 'a' <= (Char.chr (rowcode - 1)) 
       && (Char.chr (rowcode - 1)) <= 'j' && 1 <= (snd (fst point))
       && (snd (fst point))<= 10 &&
       'a' <= (Char.chr (rowcode + 1)) 
       && (Char.chr (rowcode + 1)) <= 'j' 
       && 1 <= (snd (fst point)) && (snd (fst point))<= 10 &&
       is_hit (get_point (Char.chr (rowcode + 1) , snd (fst point)) grid grid) 
       && can_fire 
         (get_point (Char.chr (rowcode - 1) , snd (fst point)) grid grid)
  then (Char.chr (rowcode - 1) , snd (fst point))  
  (*if square left is hit, shoot right *)

  else if 'a' <= (fst(fst point)) && (fst(fst point)) <= 'j'
          && 1 <= (snd (fst point)-1) && (snd (fst point)-1)<= 10  && 
          'a' <= (fst(fst point)) && (fst(fst point)) <= 'j' 
          && 1 <= (snd (fst point)+1) && (snd (fst point)+1)<= 10 &&
          is_hit (get_point ((fst(fst point) , snd(fst point)-1)) grid grid) 
          && can_fire (get_point ((fst(fst point) , snd(fst point)+1)) grid grid) 
  then (fst(fst point),snd(fst point)+1) 
  (*if square right is hit, shoot left *)

  else if 'a' <= (fst(fst point)) && (fst(fst point)) <= 'j' 
          && 1 <= (snd (fst point)-1) && (snd (fst point)-1)<= 10  && 
          'a' <= (fst(fst point)) && (fst(fst point)) <= 'j' 
          && 1 <= (snd (fst point)+1) && (snd (fst point)+1)<= 10 &&
          is_hit (get_point ((fst(fst point) , snd(fst point)+1)) grid grid) 
          && can_fire (get_point ((fst(fst point) , snd(fst point)-1)) grid grid) 
  then (fst(fst point),snd(fst point)-1) 

  (*else just check surrounding squares *)
  else if 'a' <= (Char.chr (rowcode - 1)) 
       && (Char.chr (rowcode - 1)) <= 'j' && 1 <= (snd (fst point)) 
       && (snd (fst point))<= 10 &&
       can_fire (get_point (Char.chr (rowcode - 1) , snd (fst point)) grid grid) 
  then (Char.chr (rowcode - 1) , snd (fst point))
  else if 'a' <= (Char.chr (rowcode + 1)) && (Char.chr (rowcode + 1)) <= 'j' 
          && 1 <= (snd (fst point)) && (snd (fst point))<= 10   && 
          can_fire (get_point (Char.chr (rowcode + 1) , snd (fst point)) grid grid)
  then (Char.chr (rowcode + 1) , snd (fst point)) 

  else if 'a' <= (fst(fst point)) && (fst(fst point)) <= 'j' 
          && 1 <= (snd (fst point)-1) && (snd (fst point)-1)<= 10  && 
          can_fire (get_point ((fst(fst point) , snd(fst point)-1)) grid grid) 
  then (fst(fst point) , snd(fst point)-1)
  else if 'a' <= (fst(fst point)) && (fst(fst point)) <= 'j' 
          && 1 <= (snd (fst point)+1) && (snd (fst point)+1)<= 10  && 
          can_fire (get_point ((fst(fst point) , snd(fst point)+1)) grid grid) 
  then (fst(fst point) , snd(fst point)+1)

  else let new_coord = 
         find_other_hit_coord grid ((fst point)::stale_list) grid in 
    pick_adjacent grid (get_point new_coord grid grid) 
      (Char.code (fst new_coord)) stale_list time

(** [fire_AI_coords fullgrid grid time] is a coordinate for the ai to 
    fire at. *)
let rec fire_AI_coords (fullgrid: Battleship.grid) (grid:Battleship.grid) time : 
  coordinate = 
  match grid with 
  |[] -> (generate_rnd_row (), generate_rnd_col ())
  |((r,c), Hit(s))::t -> 
    pick_adjacent fullgrid ((r,c), Hit(s)) (Char.code r) [] time
  |h::t -> fire_AI_coords fullgrid t time

(** [can_bomb state] is whether or not the user can use a bomb *)
let can_bomb state = 
  if state.bombs_left <= 0 then false else true

(** [get_bomb_coords coord] is a list of coordinates that represents the
    coordinates to be fired at in a single move when bomb is called. 
    The list of coordinates are a cross, with the center point being the 
    [coord]. *)
let get_bomb_coords coord : coordinate list = 
  let row = match coord with 
    | (r,c) -> r in 
  let col = match coord with
    | (r,c) -> c in 
  let rowASCII = Char.code row in 
  if row < 'j' && row > 'a' && col > 1 && col < 10 
  then [(Char.chr (rowASCII-1), col); (Char.chr (rowASCII+1), col); 
        coord; (row, col-1); (row, col+1)]
  else if row = 'a' && col <> 1 && col <> 10 
  then [(Char.chr (rowASCII+1), col); coord; (row, col-1); (row, col+1)]
  else if row = 'j' && col <> 1 && col <> 10 
  then [(Char.chr (rowASCII-1), col); coord; (row, col-1); (row, col+1)]
  else if col = 1 && row <> 'a' && row <> 'j'
  then [(Char.chr (rowASCII+1), col); coord; (Char.chr (rowASCII-1), col); 
        (row, col+1)]
  else if col = 10 && row <> 'a' && row <> 'j'
  then [(Char.chr (rowASCII+1), col); coord; (Char.chr (rowASCII-1), col); 
        (row, col-1)]
  else if row = 'a' && col = 1
  then [coord; (Char.chr (rowASCII+1), col); (row, col+1)]
  else if row = 'a' && col = 10 
  then [coord; (Char.chr (rowASCII+1), col); (row, col-1)]
  else if row = 'j' && col = 1
  then [coord; (Char.chr (rowASCII-1), col); (row, col+1)]
  else [coord; (Char.chr (rowASCII-1), col); (row, col-1)]

(** [bomb_helper coordsList currentState] is a helper function for [bomb] 
    that is the state of the game when a bomb is used. *)
let rec bomb_helper coordsList currentState =  
  match coordsList with 
  | [] -> {currentState with bombs_left=currentState.bombs_left-1}
  | h::t -> bomb_helper t (fire h currentState)

(** [bomb coord currentState] is the new game state resulting from bombing at 
     the given coordinate. It fires at the [coord] and the surrounding
     points adjacent to it. *)
let bomb coord currentState= 
  let coordsList = get_bomb_coords coord in 
  bomb_helper coordsList currentState

(** [winOrNot lst] is whether or not all ships have sunk in this game. *)
let winOrNot lst : bool = 
  if List.length lst = 5 then true else false

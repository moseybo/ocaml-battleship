type coordinate = char * int 
type status = Occupied | Hit | Empty  
type point = coordinate * status
type grid = point list

type name = Carrier | Battleship | Cruiser | Submarine | Destroyer  
type ship = {name: name; size: int; hits: int}


let carrier = {name = Carrier; size = 5; hits = 0}
let battleship = {name = Battleship; size = 4; hits = 0}
let cruiser = {name = Cruiser; size = 3; hits = 0}
let submarine = {name = Submarine; size = 3; hits = 0}
let destroyer = {name = Destroyer; size = 2; hits = 0}

let rows = ['a';'b';'c';'d';'e';'f';'g';'h';'i';'j']
let columns = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10]






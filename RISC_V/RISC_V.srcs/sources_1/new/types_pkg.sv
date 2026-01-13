package types_pkg;
        
    typedef struct packed {
        logic RegWrite;
        logic MemRead;
        logic MemWrite;
        logic Branch;
        logic Jump;
        logic MemToReg;
        logic ALUSrc;
        logic [3:0] ALUSel;
        logic [4:0] rd;
    } ctrl_id;
    
    typedef struct packed {
        logic RegWrite;
        logic rd;
    } ctrl_ex;

endpackage

module CmdMotPap(nStep, nReset, MotDir, OnOff, Hold, FullnHalf,Phase);

//----------------------------------------------------------------------------
localparam 	IDLE = 0;	// Sorties déconnectées (Phase = ZZZZ)
localparam 	PAS1 = 1;	// Phase = 0110   - Pas entier n°1
localparam 	PAS12= 2;  // Phase = 0010
localparam 	PAS2 = 3;	// Phase = 1010	- Pas entier n°2
localparam 	PAS23= 4;  // Phase = 1000
localparam 	PAS3 = 5;  // Phase = 1001	- Pas entier n°3
localparam 	PAS34= 6;   // Phase = 0001
localparam 	PAS4 = 7;  // Phase = 0101		- Pas entier n°4
localparam 	PAS41= 8;  // Phase = 0100
//----------------------------------------------------------------------------
localparam 	INITIAL_STATE = PAS1;	// formally sets the initial state to PAS1
//----------------------------------------------------------------------------

input nStep;		// Horloge principale
input nReset;		// Entrée de Reset externe (active état bas)
input MotDir ;		// Gestion du sens de rotation
input OnOff;		// Commande de l'alimentation des phases
input Hold;			// Maintien du couple
input FullnHalf;	// Commande en pas entiers ou 1/2 pas

//----------------------------------------------------------------------------
// Package all inputs into a single "ordered" vector
wire[3:0] 	InputVector;
assign		InputVector = {OnOff,Hold,MotDir,FullnHalf};
//----------------------------------------------------------------------------	

output[3:0] Phase;
reg[3:0] Phase;

//----------------------------------------------------------------------------
reg[3:0] EtatPresent = INITIAL_STATE;
reg[3:0] EtatFutur = INITIAL_STATE;
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
// Process #1 : Avancement de pas
always @(negedge nStep)
begin
	if (nReset == 0) EtatPresent = INITIAL_STATE;
	else	EtatPresent <= EtatFutur;
end

//----------------------------------------------------------------------------
// Process #3 : Gestion des sorties
always @(EtatPresent)
begin
	case(EtatPresent)
		IDLE : Phase <= 4'bZZZZ;
		PAS1 : Phase <= 4'b0110;
		PAS12 : Phase <= 4'b0010;
		PAS2 : Phase <= 4'b1010;
		PAS23 : Phase <= 4'b1000;
		PAS3 : Phase <= 4'b1001;
		PAS34: Phase <= 4'b0001;
		PAS4 : Phase <= 4'b0101;
		PAS41: Phase <= 4'b0100;
		default : Phase <= 4'bZZZZ; // Sécurité
	endcase
end

//----------------------------------------------------------------------------
// Process #2 : Transitions -  Codage FSM 
always @(EtatPresent, InputVector)
begin
	case(EtatPresent)
		IDLE : 	casex(InputVector)
						4'b0xxx : EtatFutur <= IDLE;	// Stop Mode
						4'b11xx : EtatFutur <= IDLE;	// Hold Mode
						4'b10xx : EtatFutur <= PAS1;	// Go to "normal" mode
					endcase
		PAS1 : 	casex(InputVector)
						4'b0xxx : EtatFutur <= IDLE;	// Stop Mode
						4'b11xx : EtatFutur <= PAS12;	// Hold Mode
						4'b1000 : EtatFutur <= PAS41;	// Counter ClockWise - Half Step
						4'b1001 : EtatFutur <= PAS4;	// Counter ClockWise - Full Step
						4'b1010 : EtatFutur <= PAS12;	// ClockWise - Half Step
						4'b1011 : EtatFutur <= PAS2;	// ClockWise - Full Step
					endcase
		PAS12 : 	casex(InputVector)
						4'b0xxx : EtatFutur <= IDLE;	// Stop Mode
						4'b11xx : EtatFutur <= PAS12;	// Hold Mode
						4'b1000 : EtatFutur <= PAS1;	// Counter ClockWise - Half Step
						4'b1001 : EtatFutur <= PAS41;	// Counter ClockWise - Full Step
						4'b1010 : EtatFutur <= PAS2;	// ClockWise - Half Step
						4'b1011 : EtatFutur <= PAS23;	// ClockWise - Full Step
					endcase
		PAS2 : 	casex(InputVector)
						4'b0xxx : EtatFutur <= IDLE;	// Stop Mode
						4'b11xx : EtatFutur <= PAS2;	// Hold Mode
						4'b1000 : EtatFutur <= PAS12;	// Counter ClockWise - Half Step
						4'b1001 : EtatFutur <= PAS1;	// Counter ClockWise - Full Step
						4'b1010 : EtatFutur <= PAS23;	// ClockWise - Half Step
						4'b1011 : EtatFutur <= PAS3;	// ClockWise - Full Step
					endcase
		PAS23 : 	casex(InputVector)
						4'b0xxx : EtatFutur <= IDLE;	// Stop Mode
						4'b11xx : EtatFutur <= PAS23;	// Hold Mode
						4'b1000 : EtatFutur <= PAS2;	// Counter ClockWise - Half Step
						4'b1001 : EtatFutur <= PAS12;	// Counter ClockWise - Full Step
						4'b1010 : EtatFutur <= PAS3;	// ClockWise - Half Step
						4'b1011 : EtatFutur <= PAS34;	// ClockWise - Full Step
					endcase
		PAS3 : 	casex(InputVector)
						4'b0xxx : EtatFutur <= IDLE;	// Stop Mode
						4'b11xx : EtatFutur <= PAS3;	// Hold Mode
						4'b1000 : EtatFutur <= PAS23;	// Counter ClockWise - Half Step
						4'b1001 : EtatFutur <= PAS2;	// Counter ClockWise - Full Step
						4'b1010 : EtatFutur <= PAS34;	// ClockWise - Half Step
						4'b1011 : EtatFutur <= PAS4;	// ClockWise - Full Step
					endcase
		PAS34 : 	casex(InputVector)
						4'b0xxx : EtatFutur <= IDLE;	// Stop Mode
						4'b11xx : EtatFutur <= PAS34;	// Hold Mode
						4'b1000 : EtatFutur <= PAS3;	// Counter ClockWise - Half Step
						4'b1001 : EtatFutur <= PAS23;	// Counter ClockWise - Full Step
						4'b1010 : EtatFutur <= PAS4;	// ClockWise - Half Step
						4'b1011 : EtatFutur <= PAS41;	// ClockWise - Full Step
					endcase
		PAS4 : 	casex(InputVector)
						4'b0xxx : EtatFutur <= IDLE;	// Stop Mode
						4'b11xx : EtatFutur <= PAS4;	// Hold Mode
						4'b1000 : EtatFutur <= PAS34;	// Counter ClockWise - Half Step
						4'b1001 : EtatFutur <= PAS3;	// Counter ClockWise - Full Step
						4'b1010 : EtatFutur <= PAS41;	// ClockWise - Half Step
						4'b1011 : EtatFutur <= PAS1;	// ClockWise - Full Step
					endcase
		PAS41 : 	casex(InputVector)
						4'b0xxx : EtatFutur <= IDLE;	// Stop Mode
						4'b11xx : EtatFutur <= PAS41;	// Hold Mode
						4'b1000 : EtatFutur <= PAS4;	// Counter ClockWise - Half Step
						4'b1001 : EtatFutur <= PAS34;	// Counter ClockWise - Full Step
						4'b1010 : EtatFutur <= PAS1;	// ClockWise - Half Step
						4'b1011 : EtatFutur <= PAS12;	// ClockWise - Full Step
					endcase
		default : EtatFutur <= IDLE;					// Security
	endcase
end
endmodule


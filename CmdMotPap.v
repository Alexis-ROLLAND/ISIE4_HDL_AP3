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
input nReset;		// Entrée de Reset (active état bas)
input MotDir ;		// Gestion du sens de rotation
input OnOff;		// Commande de l'alimentation des phases
input Hold;			// Maintien du couple
input FullnHalf;	// Commande en pas entiers ou 1/2 pas

output[3:0] Phase;	// Output vector
reg[3:0] Phase;		// is a reg

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
always @(EtatPresent, MotDir, OnOff, FullnHalf,Hold)
begin
	if (OnOff == 0) EtatFutur <= IDLE;	// OnOff identifié comme signal de type "Reset interne"
	else
	begin
		case(EtatPresent)
			//------------------------ IDLE ---------------------------------------
			IDLE : 	if ((OnOff == 0) || (Hold == 1)) EtatFutur <= IDLE;
						else EtatFutur <= PAS1;	// Loi de De Morgan
			//------------------------ PAS1 ---------------------------------------
			PAS1 : 	if (Hold == 1) EtatFutur <= PAS1;	// No need to add " && OnOff == 0 "
						else 	// We know now that Hold is low. No need to add this in the futures "if"
						begin
							if 		( (MotDir == 1) && (FullnHalf == 1) ) EtatFutur <= PAS2;		// ClockWise, Full step
							else if 	( (MotDir == 1) && (FullnHalf == 0) ) EtatFutur <= PAS12;	// ClockWise, Half step
							else if 	( (MotDir == 0) && (FullnHalf == 1) ) EtatFutur <= PAS4;		// Counter ClockWise, Half step
							else														  EtatFutur <= PAS41;	// Counter ClockWise, Half step
						end
			//------------------------ PAS12 ---------------------------------------
			PAS12 : 	if (Hold == 1) EtatFutur <= PAS12;	// No need to add " && OnOff == 0 "
						else 	// We know now that Hold is low. No need to add this in the futures "if"
						begin
							if 		( (MotDir == 1) && (FullnHalf == 1) ) EtatFutur <= PAS23;	// ClockWise, Full step
							else if 	( (MotDir == 1) && (FullnHalf == 0) ) EtatFutur <= PAS2;		// ClockWise, Half step
							else if 	( (MotDir == 0) && (FullnHalf == 1) ) EtatFutur <= PAS41;	// Counter ClockWise, Half step
							else														  EtatFutur <= PAS1;		// Counter ClockWise, Half step
						end
		
			//------------------------ PAS2 ---------------------------------------
			PAS2 : 	if (Hold == 1) EtatFutur <= PAS2;	// No need to add " && OnOff == 0 "
						else 	// We know now that Hold is low. No need to add this in the futures "if"
						begin
							if 		( (MotDir == 1) && (FullnHalf == 1) ) EtatFutur <= PAS3;		// ClockWise, Full step
							else if 	( (MotDir == 1) && (FullnHalf == 0) ) EtatFutur <= PAS23;	// ClockWise, Half step
							else if 	( (MotDir == 0) && (FullnHalf == 1) ) EtatFutur <= PAS1;		// Counter ClockWise, Half step
							else														  EtatFutur <= PAS12;	// Counter ClockWise, Half step
						end
			//------------------------ PAS23 ---------------------------------------
			PAS23 : 	if (Hold == 1) EtatFutur <= PAS23;	// No need to add " && OnOff == 0 "
						else 	// We know now that Hold is low. No need to add this in the futures "if"
						begin
							if 		( (MotDir == 1) && (FullnHalf == 1) ) EtatFutur <= PAS34;	// ClockWise, Full step
							else if 	( (MotDir == 1) && (FullnHalf == 0) ) EtatFutur <= PAS3;		// ClockWise, Half step
							else if 	( (MotDir == 0) && (FullnHalf == 1) ) EtatFutur <= PAS12;	// Counter ClockWise, Half step
							else														  EtatFutur <= PAS2;		// Counter ClockWise, Half step
						end
			//------------------------ PAS3 ---------------------------------------
			PAS3 : 	if (Hold == 1) EtatFutur <= PAS3;	// No need to add " && OnOff == 0 "
						else 	// We know now that Hold is low. No need to add this in the futures "if"
						begin
							if 		( (MotDir == 1) && (FullnHalf == 1) ) EtatFutur <= PAS4;		// ClockWise, Full step
							else if 	( (MotDir == 1) && (FullnHalf == 0) ) EtatFutur <= PAS34;	// ClockWise, Half step
							else if 	( (MotDir == 0) && (FullnHalf == 1) ) EtatFutur <= PAS2;		// Counter ClockWise, Half step
							else														  EtatFutur <= PAS23;	// Counter ClockWise, Half step
						end
			//------------------------ PAS34 ---------------------------------------
			PAS34 : 	if (Hold == 1) EtatFutur <= PAS34;	// No need to add " && OnOff == 0 "
						else 	// We know now that Hold is low. No need to add this in the futures "if"
						begin
							if 		( (MotDir == 1) && (FullnHalf == 1) ) EtatFutur <= PAS41;	// ClockWise, Full step
							else if 	( (MotDir == 1) && (FullnHalf == 0) ) EtatFutur <= PAS4;		// ClockWise, Half step
							else if 	( (MotDir == 0) && (FullnHalf == 1) ) EtatFutur <= PAS23;	// Counter ClockWise, Half step
							else														  EtatFutur <= PAS3;		// Counter ClockWise, Half step
						end
			//------------------------ PAS4 ---------------------------------------
			PAS4 : 	if (Hold == 1) EtatFutur <= PAS4;	// No need to add " && OnOff == 0 "
						else 	// We know now that Hold is low. No need to add this in the futures "if"
						begin
							if 		( (MotDir == 1) && (FullnHalf == 1) ) EtatFutur <= PAS1;		// ClockWise, Full step
							else if 	( (MotDir == 1) && (FullnHalf == 0) ) EtatFutur <= PAS41;	// ClockWise, Half step
							else if 	( (MotDir == 0) && (FullnHalf == 1) ) EtatFutur <= PAS3;		// Counter ClockWise, Half step
							else														  EtatFutur <= PAS34;	// Counter ClockWise, Half step
						end
			//------------------------ PAS41 ---------------------------------------
			PAS41 : 	if (Hold == 1) EtatFutur <= PAS34;	// No need to add " && OnOff == 0 "
						else 	// We know now that Hold is low. No need to add this in the futures "if"
						begin
							if 		( (MotDir == 1) && (FullnHalf == 1) ) EtatFutur <= PAS12;	// ClockWise, Full step
							else if 	( (MotDir == 1) && (FullnHalf == 0) ) EtatFutur <= PAS1;		// ClockWise, Half step
							else if 	( (MotDir == 0) && (FullnHalf == 1) ) EtatFutur <= PAS34;	// Counter ClockWise, Half step
							else														  EtatFutur <= PAS4;		// Counter ClockWise, Half step
						end
			//--------------------------- Security	------------------------------
			default : EtatFutur <= IDLE;
					
					
					
					
	endcase
	end
end
endmodule


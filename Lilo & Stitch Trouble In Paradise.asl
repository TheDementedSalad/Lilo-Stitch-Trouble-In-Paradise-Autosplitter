state("LiveSplit") {}

startup
{
	// Creates a persistent instance of the PS1 class (for PS1 emulators)
	Assembly.Load(File.ReadAllBytes("Components/emu-help-v2")).CreateInstance("PS1");
	
	// You can look up for known IDs on https://psxdatacenter.com/
	vars.Helper.Load = (Func<dynamic, bool>)(emu => 
    {
	//Address of Gamecode (This can be multiple addresses in some cases
		emu.MakeString("P_Gamecode", 10, 0x800B9A02);		//SCES-03871
		emu.MakeString("U_Gamecode", 10, 0x800B99E6);		//SCUS-94646
		//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		//These are for the PAL (English) Version of the game
		emu.Make<byte>("P_Loading", 0x800C9470);
		emu.Make<byte>("P_LvlComp", 0x800C9B74);
		emu.Make<byte>("P_LvlType", 0x800C87EC);
		emu.Make<byte>("P_LvlNo", 0x800C87F8);
		emu.Make<byte>("P_Paused", 0x800C87E1);
		
		//These are for the NTSC-U (US) Version of the game
		emu.Make<byte>("U_Loading", 0x800C9448);
		emu.Make<byte>("U_LvlComp", 0x800C9B4C);
		emu.Make<byte>("U_LvlType", 0x800C87C4);
		emu.Make<byte>("U_LvlNo", 0x800C87D0);
		emu.Make<byte>("U_Paused", 0x800C87B9);
		return true;
    });
	
	vars.LvlID = new List<string>(){
	"1_1", "1_2", "1_3", "1_4", "1_15", "1_9", "1_8", "1_13",
	"1_5", "1_16", "1_10", "1_12", "1_11", "1_14", "End"};
	
	vars.LvlName = new List<string>(){
	"Koa Wood", "Koana Road", "Mea Kanu Trial", "Malie Beach", "Mertle!", "Iniki Track", "Haleakala Beach", "Mokihana Gardens",
	"Guava River", "Jumba!", "Heiau Valley", "Pali Trail", "Kapu Caves", "Kokoke Trail", "Gantu!"};
	
	settings.Add("Lvl", false, "Level Splits");
		settings.CurrentDefaultParent = "Lvl";
		for(int i = 0; i < 15; i++){
        	settings.Add("" + vars.LvlID[i].ToString(), false, "" + vars.LvlName[i].ToString());
    	}
		settings.CurrentDefaultParent = null;
}

init
{
	//Create a list that can hold our completed split strings
	vars.completedSplits = new HashSet<string>();
}

update
{
	// get a casted (to dictionary) reference to current
	// so we can manipulate it using dynamic keynames
	var cur = current as IDictionary<string, object>;

	// list of pc address names to be recreated when on emu
	var names = new List<string>() {
		"Loading",
		"LvlComp",
		"LvlType",
		"LvlNo",
		"Paused"
	};

	// (placeholder) have some logic to work out the version and create the prefix
	string ver = null;

	// assign version based on gamecode
	if (current.P_Gamecode == "SCES-03871") ver = "P_";
	if (current.U_Gamecode == "SCUS-94646") ver = "U_";

	// if in a supported version of the game...
	if (ver == null) return false;
	// loop through each desired address...
	foreach(string name in names) {
		// set e.g. current.GameTime to the value at e.g. current.US_GameTime
		cur[name] = cur[ver + name];
	}
}

onStart
{
	//Clear the variable on start
	vars.completedSplits.Clear();
}

start
{
	if(current.LvlType == 0 && current.LvlNo == 1 && current.Loading == 1 && old.Loading == 0){
		return true;
	}
}

split
{
	string setting = "";
	
	if((current.LvlNo != old.LvlNo || current.LvlType != old.LvlType) && current.Paused == 0){
		setting = old.LvlType + "_" + old.LvlNo;
	}
	
	if(current.LvlType == 1 && current.LvlNo == 7 && current.LvlComp == 0 && old.LvlComp == 255){
		setting = "End";
	}
	
	// Debug. Comment out before release (prints the setting to a debugger)
    if (!string.IsNullOrEmpty(setting)){
		print(setting);
	}
	
	if (settings.ContainsKey(setting) && settings[setting] && vars.completedSplits.Add(setting)) {
		return true;
	}
}

isLoading
{
	return current.Loading == 0;
}

reset
{
	if(current.LvlType == 0 && current.LvlNo == 1 && current.Loading == 1 && old.Loading == 0){
		return true;
		vars.completedSplits.Clear();
	}
}

shutdown
{
	// Please don't remove this line from this block
	vars.Helper.Dispose();
}


function Equus_LoadLocals()
	local lang = GetLocale()
	
	if lang == "frFR" then
		Equus_Localization = {
			["Black"] = "Noir",
			["Gray"] = "Gris",
			["White"] = "Blanc",
			["Brown"] = "Marron",
			["Red"] = "Rouge",
			["Orange"] = "Orange",
			["Yellow"] = "Jaune",
			["Green"] = "Vern",
			["Blue"] = "Bleu",
			["Purple"] = "Violet",
			["Pink"] = "Rose",
		}
	elseif strsub(lang,1,2) == "es" then -- Catch esES and esMX. Fix discrepancies later.
		Equus_Localization = {
			["Error processing mount"] = "Error procesando montura",
			["Please report this via curse.com"] = "Por favor, informa de esto v�a curse.com",
			["EquusInfinata loaded. Type \"/ei help\" for details."] = "EquusInfinata cargado. Escribe \"/ei help\" para m�s informaci�n.",
			["Treat 310% flying mounts as 280%"] = "Tratar las monturas voladoras 310% como 280%",
			["If this is enabled, when summoning a random mount the addon will not prioritise 310% flying mounts over 280% flying mounts, giving a larger selection."] = "Si esto esta activado, cuando se invoque a una montura aleatoria no priorizar� a las monturas voladoras de 310% por encima de las de 280%, dando una mayor selecci�n.",
			["Hide passenger filter"] = "Ocultar filtro de pasajero",
			["If this is enabled, the filter options for number of passengers will be hidden from the Equus Infinata screen."] = "Si esto esta activado, el filtro de opciones por n�mero de pasajeros ser� ocultado en la pantalla de Equus Infinata.",
			["Hide colour filter"] = "Ocultar filtro de color",
			["If this is enabled, the filter options for the colour of your mount will be hidden from the Equus Infinata screen."] = "Si esto esta activado, el filtro de opciones para el color de tu montura ser� ocultado de la pantalla de Equus Infinata.",
			["Options"] = "Opciones",
			["AllPassengers"] = "TodasPasajeros",
			["NoPassengers"] = "SinPasajeros",
			["OnePassenger"] = "UnPasajero",
			["TwoPassengers"] = "DosPasajeros",
			["AllSpeeds"] = "TodasVelocidads",
			["NoSpeed"] = "SinVelocidad",
			["Swimming"] = "Nadadora",
			["Changes"] = "Cambiante",
			["SlowGround"] = "TerrestreLenta",
			["FastGround"] = "TerrestreR�pida",
			["SlowFlying"] = "A�reaLenta",
			["FastFlying"] = "A�reaR�pida",
			["VeryFastFlying"] = "A�reaMuyR�pida",
			["AllSpecies"] = "TodasEspecies",
			["Raptor"] = "Raptor",
			["Kodo"] = "Kodo",
			["Wolf"] = "Lobo",
			["Tiger"] = "Tigre",
			["Ram"] = "Carnero",
			["Skeletal Horse"] = "CaballoEsquel�tico",
			["Horse"] = "Caballo",
			["Mechanostrider"] = "Mecazancudo",
			["Elekk"] = "Elekk",
			["Hawkstrider"] = "Halc�nZancudo",
			["Talbuk"] = "Talbuk",
			["Mammoth"] = "Mamut",
			["Silithid"] = "Silithido",
			["Mechanical"] = "Mec�nica",
			["Bear"] = "Oso",
			["Turtle"] = "Tortuga",
			["Wind Rider"] = "JineteDelViento",
			["Dragonhawk"] = "Dracohalc�n",
			["Gryphon"] = "Grifo",
			["Hippogryph"] = "Hipogrifo",
			["Nether Ray"] = "RayaAbisal",
			["Netherdrake"] = "DracoAbisal",
			["Proto Drake"] = "Protodraco",
			["Drake"] = "Draco",
			["Frostwyrm"] = "VermisDeEscarcha",
			["Carpet"] = "Alfombra",
			["Zhevra"] = "Zhebra",
			["Raven"] = "Cuervo",
			["Rooster"] = "Gallo",
			["Skeletal Gryphon"] = "GrifoEsquel�tico",
			["Phoenix"] = "F�nix",
			["Unknown"] = "Desconocido",
			["AllColours"] = "TodasColors",
			["Black"] = "Negras",
			["Gray"] = "Grises",
			["White"] = "Blancas",
			["Brown"] = "Marrones",
			["Red"] = "Rojas",
			["Orange"] = "Naranjas",
			["Yellow"] = "Amarillas",
			["Green"] = "Verdes",
			["Blue"] = "Azules",
			["Purple"] = "Moradas",
			["Pink"] = "Rosas",
		}
	else
		Equus_Localization = {}
	end
	EquusLocalized = 1
end

function EqLoc(text)
	if not EquusLocalized or EquusLocalized ~= 1 then
		Equus_LoadLocals()
	end
	
	if Equus_Localization[text] then
		return Equus_Localization[text]
	else
		return text
	end
end
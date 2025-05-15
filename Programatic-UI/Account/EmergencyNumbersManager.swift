import CoreLocation

class EmergencyNumbersManager {
    private static let numbersByCountry: [String: [String: String]] = [
        "AF": [ // Afghanistan
            "Ambulance": "112",
            "Police": "119",
            "Women Helpline": "112"
        ],
        "AL": [ // Albania
            "Ambulance": "127",
            "Police": "129",
            "Women Helpline": "116"        ],
        "DZ": [ // Algeria
            "Ambulance": "14",
            "Police": "17",
            "Women Helpline": "1525" // Women-specific support line
        ],
        "AD": [ // Andorra
            "Ambulance": "118",
            "Police": "110",
            "Women Helpline": "181" // Domestic violence helpline
        ],
        "AO": [ // Angola
            "Ambulance": "115",
            "Police": "113",
            "Women Helpline": "112" // General emergency
        ],
        "AG": [ // Antigua and Barbuda
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "999" // General emergency
        ],
        "AR": [ // Argentina
            "Ambulance": "107",
            "Police": "101",
            "Women Helpline": "144" // National women’s helpline
        ],
        "AM": [ // Armenia
            "Ambulance": "103",
            "Police": "102",
            "Women Helpline": "0800-80-850" // Women’s support hotline
        ],
        "AU": [ // Australia
            "Ambulance": "000",
            "Police": "000",
            "Women Helpline": "1800737732" // 1800 RESPECT (National Sexual Assault, Domestic Violence)
        ],
        "AT": [ // Austria
            "Ambulance": "144",
            "Police": "133",
            "Women Helpline": "0800222555" // Women’s helpline
        ],
        "AZ": [ // Azerbaijan
            "Ambulance": "103",
            "Police": "102",
            "Women Helpline": "112" // General emergency
        ],
        "BS": [ // Bahamas
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "919" // General emergency
        ],
        "BH": [ // Bahrain
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "80008100" // Family helpline, includes women
        ],
        "BD": [ // Bangladesh
            "Ambulance": "199",
            "Police": "999",
            "Women Helpline": "109" // National helpline for women and children
        ],
        "BB": [ // Barbados
            "Ambulance": "511",
            "Police": "211",
            "Women Helpline": "435-8222" // Women’s crisis hotline
        ],
        "BY": [ // Belarus
            "Ambulance": "103",
            "Police": "102",
            "Women Helpline": "801100" // Domestic violence helpline
        ],
        "BE": [ // Belgium
            "Ambulance": "100",
            "Police": "101",
            "Women Helpline": "080030030" // Violence helpline, women-focused
        ],
        "BZ": [ // Belize
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "08009266" // Women’s helpline
        ],
        "BJ": [ // Benin
            "Ambulance": "118",
            "Police": "117",
            "Women Helpline": "112" // General emergency
        ],
        "BT": [ // Bhutan
            "Ambulance": "112",
            "Police": "113",
            "Women Helpline": "1098" // Child and women helpline
        ],
        "BO": [ // Bolivia
            "Ambulance": "118",
            "Police": "110",
            "Women Helpline": "800140071" // Women’s helpline
        ],
        "BA": [ // Bosnia and Herzegovina
            "Ambulance": "124",
            "Police": "122",
            "Women Helpline": "1265" // SOS helpline for women
        ],
        "BW": [ // Botswana
            "Ambulance": "997",
            "Police": "999",
            "Women Helpline": "3900577" // Gender-based violence helpline
        ],
        "BR": [ // Brazil
            "Ambulance": "192",
            "Police": "190",
            "Women Helpline": "180" // Central de Atendimento à Mulher
        ],
        "BN": [ // Brunei
            "Ambulance": "991",
            "Police": "993",
            "Women Helpline": "141" // Helpline for abuse victims
        ],
        "BG": [ // Bulgaria
            "Ambulance": "150",
            "Police": "166",
            "Women Helpline": "080018676" // Women’s helpline
        ],
        "BF": [ // Burkina Faso
            "Ambulance": "112",
            "Police": "17",
            "Women Helpline": "116" // Child and women helpline
        ],
        "BI": [ // Burundi
            "Ambulance": "117",
            "Police": "112",
            "Women Helpline": "118" // General emergency
        ],
        "KH": [ // Cambodia
            "Ambulance": "119",
            "Police": "117",
            "Women Helpline": "1280" // Women’s support line
        ],
        "CM": [ // Cameroon
            "Ambulance": "112",
            "Police": "117",
            "Women Helpline": "116" // Child and women helpline
        ],
        "CA": [ // Canada
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "18003636366" // National Domestic Violence Hotline
        ],
        "CV": [ // Cape Verde
            "Ambulance": "130",
            "Police": "132",
            "Women Helpline": "112" // General emergency
        ],
        "CF": [ // Central African Republic
            "Ambulance": "117",
            "Police": "112",
            "Women Helpline": "118" // General emergency
        ],
        "TD": [ // Chad
            "Ambulance": "2251-4242",
            "Police": "17",
            "Women Helpline": "112" // General emergency
        ],
        "CL": [ // Chile
            "Ambulance": "131",
            "Police": "133",
            "Women Helpline": "1455" // Women’s violence helpline
        ],
        "CN": [ // China
            "Ambulance": "120",
            "Police": "110",
            "Women Helpline": "12338" // Women’s federation helpline
        ],
        "CO": [ // Colombia
            "Ambulance": "125",
            "Police": "123",
            "Women Helpline": "155" // National women’s helpline
        ],
        "KM": [ // Comoros
            "Ambulance": "772-03-73",
            "Police": "17",
            "Women Helpline": "18" // General emergency
        ],
        "CG": [ // Congo (Republic of the)
            "Ambulance": "118",
            "Police": "117",
            "Women Helpline": "112" // General emergency
        ],
        "CD": [ // Congo (Democratic Republic of the)
            "Ambulance": "118",
            "Police": "112",
            "Women Helpline": "117" // General emergency
        ],
        "CR": [ // Costa Rica
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "800-300-6000" // Women’s helpline
        ],
        "CI": [ // Côte d'Ivoire
            "Ambulance": "185",
            "Police": "170",
            "Women Helpline": "130" // Gender-based violence helpline
        ],
        "HR": [ // Croatia
            "Ambulance": "194",
            "Police": "192",
            "Women Helpline": "0800-5555" // Women’s SOS line
        ],
        "CU": [ // Cuba
            "Ambulance": "104",
            "Police": "106",
            "Women Helpline": "103" // General helpline, women included
        ],
        "CY": [ // Cyprus
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "1440" // Women’s support line
        ],
        "CZ": [ // Czech Republic
            "Ambulance": "155",
            "Police": "158",
            "Women Helpline": "116006" // Violence victims helpline
        ],
        "DK": [ // Denmark
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "1888" // National women’s helpline
        ],
        "DJ": [ // Djibouti
            "Ambulance": "19",
            "Police": "17",
            "Women Helpline": "151" // Women’s support
        ],
        "DM": [ // Dominica
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "911" // General emergency
        ],
        "DO": [ // Dominican Republic
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "809-689-7212" // Women’s helpline
        ],
        "EC": [ // Ecuador
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "1800-150-150" // Violence against women helpline
        ],
        "EG": [ // Egypt
            "Ambulance": "123",
            "Police": "122",
            "Women Helpline": "16000" // National Council for Women helpline
        ],
        "SV": [ // El Salvador
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "126" // Women’s violence helpline
        ],
        "GQ": [ // Equatorial Guinea
            "Ambulance": "114",
            "Police": "112",
            "Women Helpline": "117" // General emergency
        ],
        "ER": [ // Eritrea
            "Ambulance": "114",
            "Police": "113",
            "Women Helpline": "112" // General emergency
        ],
        "EE": [ // Estonia
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "1492" // Women’s support line
        ],
        "SZ": [ // Eswatini
            "Ambulance": "977",
            "Police": "999",
            "Women Helpline": "975" // Gender-based violence helpline
        ],
        "ET": [ // Ethiopia
            "Ambulance": "907",
            "Police": "911",
            "Women Helpline": "112" // General emergency
        ],
        "FJ": [ // Fiji
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "1560" // Fiji Women’s Crisis Centre
        ],
        "FI": [ // Finland
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "0800117999" // Women’s Line
        ],
        "FR": [ // France
            "Ambulance": "15",
            "Police": "17",
            "Women Helpline": "3919" // Domestic violence helpline
        ],
        "GA": [ // Gabon
            "Ambulance": "1300",
            "Police": "1730",
            "Women Helpline": "112" // General emergency
        ],
        "GM": [ // Gambia
            "Ambulance": "116",
            "Police": "117",
            "Women Helpline": "1313" // Gender-based violence helpline
        ],
        "GE": [ // Georgia
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "116006" // Violence victims helpline
        ],
        "DE": [ // Germany
            "Ambulance": "112",
            "Police": "110",
            "Women Helpline": "08000116016" // National women’s helpline
        ],
        "GH": [ // Ghana
            "Ambulance": "193",
            "Police": "191",
            "Women Helpline": "0800-10-555" // Domestic violence helpline
        ],
        "GR": [ // Greece
            "Ambulance": "166",
            "Police": "100",
            "Women Helpline": "15900" // SOS line for women
        ],
        "GD": [ // Grenada
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "434" // General emergency
        ],
        "GT": [ // Guatemala
            "Ambulance": "128",
            "Police": "110",
            "Women Helpline": "1572" // Women’s helpline
        ],
        "GN": [ // Guinea
            "Ambulance": "117",
            "Police": "112",
            "Women Helpline": "114" // General emergency
        ],
        "GW": [ // Guinea-Bissau
            "Ambulance": "118",
            "Police": "117",
            "Women Helpline": "112" // General emergency
        ],
        "GY": [ // Guyana
            "Ambulance": "913",
            "Police": "911",
            "Women Helpline": "914" // Domestic violence helpline
        ],
        "HT": [ // Haiti
            "Ambulance": "114",
            "Police": "112",
            "Women Helpline": "116" // General emergency
        ],
        "HN": [ // Honduras
            "Ambulance": "195",
            "Police": "911",
            "Women Helpline": "114" // Women’s helpline
        ],
        "HU": [ // Hungary
            "Ambulance": "104",
            "Police": "107",
            "Women Helpline": "0800505522" // Women’s crisis line
        ],
        "IS": [ // Iceland
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "561-1205" // Women’s shelter helpline
        ],
        "IN": [ // India
            "Ambulance": "102",
            "Police": "100",
            "Women Helpline": "1091" // National women helpline
        ],
        "ID": [ // Indonesia
            "Ambulance": "118",
            "Police": "110",
            "Women Helpline": "129" // Women and children helpline
        ],
        "IR": [ // Iran
            "Ambulance": "115",
            "Police": "110",
            "Women Helpline": "123" // Social emergency helpline
        ],
        "IQ": [ // Iraq
            "Ambulance": "122",
            "Police": "104",
            "Women Helpline": "115" // General emergency
        ],
        "IE": [ // Ireland
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "1800341900" // Women’s Aid helpline
        ],
        "IL": [ // Israel
            "Ambulance": "101",
            "Police": "100",
            "Women Helpline": "1202" // Women’s distress line
        ],
        "IT": [ // Italy
            "Ambulance": "118",
            "Police": "113",
            "Women Helpline": "1522" // Anti-violence helpline for women
        ],
        "JM": [ // Jamaica
            "Ambulance": "110",
            "Police": "119",
            "Women Helpline": "888-991-4357" // Women’s crisis centre
        ],
        "JP": [ // Japan
            "Ambulance": "119",
            "Police": "110",
            "Women Helpline": "0570-000-911" // Domestic violence helpline
        ],
        "JO": [ // Jordan
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "110" // Family protection helpline
        ],
        "KZ": [ // Kazakhstan
            "Ambulance": "103",
            "Police": "102",
            "Women Helpline": "150" // National women’s helpline
        ],
        "KE": [ // Kenya
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "1195" // Gender violence helpline
        ],
        "KI": [ // Kiribati
            "Ambulance": "994",
            "Police": "992",
            "Women Helpline": "911" // General emergency
        ],
        "KP": [ // North Korea
            "Ambulance": "119",
            "Police": "112",
            "Women Helpline": "114" // General emergency (limited data)
        ],
        "KR": [ // South Korea
            "Ambulance": "119",
            "Police": "112",
            "Women Helpline": "1366" // Women’s emergency helpline
        ],
        "KW": [ // Kuwait
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "147" // Family and women helpline
        ],
        "KG": [ // Kyrgyzstan
            "Ambulance": "103",
            "Police": "102",
            "Women Helpline": "112" // General emergency
        ],
        "LA": [ // Laos
            "Ambulance": "195",
            "Police": "191",
            "Women Helpline": "1362" // Women’s helpline
        ],
        "LV": [ // Latvia
            "Ambulance": "113",
            "Police": "110",
            "Women Helpline": "116006" // Violence victims helpline
        ],
        "LB": [ // Lebanon
            "Ambulance": "140",
            "Police": "112",
            "Women Helpline": "1745" // Domestic violence helpline
        ],
        "LS": [ // Lesotho
            "Ambulance": "121",
            "Police": "123",
            "Women Helpline": "112" // General emergency
        ],
        "LR": [ // Liberia
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "116" // Child and women helpline
        ],
        "LY": [ // Libya
            "Ambulance": "1515",
            "Police": "193",
            "Women Helpline": "112" // General emergency
        ],
        "LI": [ // Liechtenstein
            "Ambulance": "144",
            "Police": "117",
            "Women Helpline": "0800661166" // Women’s helpline
        ],
        "LT": [ // Lithuania
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "880066366" // Women’s helpline
        ],
        "LU": [ // Luxembourg
            "Ambulance": "112",
            "Police": "113",
            "Women Helpline": "12345" // Women’s support line
        ],
        "MG": [ // Madagascar
            "Ambulance": "117",
            "Police": "118",
            "Women Helpline": "112" // General emergency
        ],
        "MW": [ // Malawi
            "Ambulance": "998",
            "Police": "997",
            "Women Helpline": "5600" // Gender-based violence helpline
        ],
        "MY": [ // Malaysia
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "15999" // Talian Nur (Women’s helpline)
        ],
        "MV": [ // Maldives
            "Ambulance": "102",
            "Police": "119",
            "Women Helpline": "141" // Family and women helpline
        ],
        "ML": [ // Mali
            "Ambulance": "15",
            "Police": "17",
            "Women Helpline": "116" // Child and women helpline
        ],
        "MT": [ // Malta
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "179" // Supportline, includes women
        ],
        "MH": [ // Marshall Islands
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "625-8666" // General helpline
        ],
        "MR": [ // Mauritania
            "Ambulance": "118",
            "Police": "117",
            "Women Helpline": "112" // General emergency
        ],
        "MU": [ // Mauritius
            "Ambulance": "114",
            "Police": "112",
            "Women Helpline": "139" // Domestic violence helpline
        ],
        "MX": [ // Mexico
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "800-108-4053" // Women’s violence helpline
        ],
        "FM": [ // Micronesia
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "320-2221" // General helpline
        ],
        "MD": [ // Moldova
            "Ambulance": "903",
            "Police": "902",
            "Women Helpline": "080088008" // Women’s helpline
        ],
        "MC": [ // Monaco
            "Ambulance": "18",
            "Police": "17",
            "Women Helpline": "112" // General emergency
        ],
        "MN": [ // Mongolia
            "Ambulance": "103",
            "Police": "102",
            "Women Helpline": "107" // Domestic violence helpline
        ],
        "ME": [ // Montenegro
            "Ambulance": "124",
            "Police": "122",
            "Women Helpline": "0800111011" // SOS helpline for women
        ],
        "MA": [ // Morocco
            "Ambulance": "15",
            "Police": "19",
            "Women Helpline": "180" // Women’s support line
        ],
        "MZ": [ // Mozambique
            "Ambulance": "117",
            "Police": "119",
            "Women Helpline": "112" // General emergency
        ],
        "MM": [ // Myanmar
            "Ambulance": "192",
            "Police": "199",
            "Women Helpline": "191" // General emergency
        ],
        "NA": [ // Namibia
            "Ambulance": "10111",
            "Police": "10111",
            "Women Helpline": "106" // Gender-based violence helpline
        ],
        "NR": [ // Nauru
            "Ambulance": "111",
            "Police": "110",
            "Women Helpline": "112" // General emergency
        ],
        "NP": [ // Nepal
            "Ambulance": "102",
            "Police": "100",
            "Women Helpline": "1111" // Women’s helpline
        ],
        "NL": [ // Netherlands
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "0800-2000" // Domestic violence helpline
        ],
        "NZ": [ // New Zealand
            "Ambulance": "111",
            "Police": "111",
            "Women Helpline": "0800733843" // Women’s Refuge
        ],
        "NI": [ // Nicaragua
            "Ambulance": "128",
            "Police": "118",
            "Women Helpline": "133" // Women’s helpline
        ],
        "NE": [ // Niger
            "Ambulance": "15",
            "Police": "17",
            "Women Helpline": "116" // Child and women helpline
        ],
        "NG": [ // Nigeria
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "0800-721-5876" // Women’s helpline
        ],
        "NO": [ // Norway
            "Ambulance": "113",
            "Police": "112",
            "Women Helpline": "80040007" // Crisis helpline for women
        ],
        "OM": [ // Oman
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "112" // General emergency
        ],
        "PK": [ // Pakistan
            "Ambulance": "115",
            "Police": "15",
            "Women Helpline": "1043" // Women’s helpline
        ],
        "PW": [ // Palau
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "112" // General emergency
        ],
        "PA": [ // Panama
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "182" // Women’s violence helpline
        ],
        "PG": [ // Papua New Guinea
            "Ambulance": "111",
            "Police": "112",
            "Women Helpline": "71508000" // Family violence helpline
        ],
        "PY": [ // Paraguay
            "Ambulance": "141",
            "Police": "911",
            "Women Helpline": "137" // SOS Mujer
        ],
        "PE": [ // Peru
            "Ambulance": "116",
            "Police": "105",
            "Women Helpline": "100" // Línea 100 (Women’s helpline)
        ],
        "PH": [ // Philippines
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "112" // General emergency
        ],
        "PL": [ // Poland
            "Ambulance": "999",
            "Police": "997",
            "Women Helpline": "800120002" // Blue Line (Women’s helpline)
        ],
        "PT": [ // Portugal
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "800202148" // Domestic violence helpline
        ],
        "QA": [ // Qatar
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "919" // Family helpline
        ],
        "RO": [ // Romania
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "0800500333" // Domestic violence helpline
        ],
        "RU": [ // Russia
            "Ambulance": "03",
            "Police": "02",
            "Women Helpline": "88007000600" // National women’s helpline
        ],
        "RW": [ // Rwanda
            "Ambulance": "912",
            "Police": "112",
            "Women Helpline": "116" // Child and women helpline
        ],
        "KN": [ // Saint Kitts and Nevis
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "999" // General emergency
        ],
        "LC": [ // Saint Lucia
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "999" // General emergency
        ],
        "VC": [ // Saint Vincent and the Grenadines
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "999" // General emergency
        ],
        "WS": [ // Samoa
            "Ambulance": "994",
            "Police": "999",
            "Women Helpline": "800-787" // Samoa Victim Support
        ],
        "SM": [ // San Marino
            "Ambulance": "118",
            "Police": "113",
            "Women Helpline": "112" // General emergency
        ],
        "ST": [ // Sao Tome and Principe
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "117" // General emergency
        ],
        "SA": [ // Saudi Arabia
            "Ambulance": "997",
            "Police": "999",
            "Women Helpline": "1919" // Family violence helpline
        ],
        "SN": [ // Senegal
            "Ambulance": "15",
            "Police": "17",
            "Women Helpline": "116" // Child and women helpline
        ],
        "RS": [ // Serbia
            "Ambulance": "194",
            "Police": "192",
            "Women Helpline": "0800100210" // SOS women’s helpline
        ],
        "SC": [ // Seychelles
            "Ambulance": "151",
            "Police": "999",
            "Women Helpline": "112" // General emergency
        ],
        "SL": [ // Sierra Leone
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "116" // Child and women helpline
        ],
        "SG": [ // Singapore
            "Ambulance": "995",
            "Police": "999",
            "Women Helpline": "1800-777-5555" // Women’s helpline
        ],
        "SK": [ // Slovakia
            "Ambulance": "155",
            "Police": "158",
            "Women Helpline": "0800212212" // Women’s helpline
        ],
        "SI": [ // Slovenia
            "Ambulance": "112",
            "Police": "113",
            "Women Helpline": "08001155" // SOS helpline for women
        ],
        "SB": [ // Solomon Islands
            "Ambulance": "911",
            "Police": "999",
            "Women Helpline": "911" // General emergency
        ],
        "SO": [ // Somalia
            "Ambulance": "999",
            "Police": "888",
            "Women Helpline": "112" // General emergency
        ],
        "ZA": [ // South Africa
            "Ambulance": "10177",
            "Police": "10111",
            "Women Helpline": "0800150150" // National GBV helpline
        ],
        "SS": [ // South Sudan
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "112" // General emergency
        ],
        "ES": [ // Spain
            "Ambulance": "061",
            "Police": "091",
            "Women Helpline": "016" // Violence against women helpline
        ],
        "LK": [ // Sri Lanka
            "Ambulance": "110",
            "Police": "119",
            "Women Helpline": "1938" // Women’s helpline
        ],
        "SD": [ // Sudan
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "112" // General emergency
        ],
        "SR": [ // Suriname
            "Ambulance": "113",
            "Police": "115",
            "Women Helpline": "112" // General emergency
        ],
        "SE": [ // Sweden
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "020505050" // Women’s helpline
        ],
        "CH": [ // Switzerland
            "Ambulance": "144",
            "Police": "117",
            "Women Helpline": "0800661123" // Women’s helpline
        ],
        "SY": [ // Syria
            "Ambulance": "110",
            "Police": "112",
            "Women Helpline": "113" // General emergency
        ],
        "TJ": [ // Tajikistan
            "Ambulance": "103",
            "Police": "102",
            "Women Helpline": "112" // General emergency
        ],
        "TZ": [ // Tanzania
            "Ambulance": "114",
            "Police": "112",
            "Women Helpline": "116" // Child and women helpline
        ],
        "TH": [ // Thailand
            "Ambulance": "1669",
            "Police": "191",
            "Women Helpline": "1300" // Women’s helpline
        ],
        "TL": [ // Timor-Leste
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "113" // General emergency
        ],
        "TG": [ // Togo
            "Ambulance": "118",
            "Police": "117",
            "Women Helpline": "116" // Child and women helpline
        ],
        "TO": [ // Tonga
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "999" // General emergency
        ],
        "TT": [ // Trinidad and Tobago
            "Ambulance": "811",
            "Police": "999",
            "Women Helpline": "800-2673" // Domestic violence helpline
        ],
        "TN": [ // Tunisia
            "Ambulance": "190",
            "Police": "197",
            "Women Helpline": "1809" // Women’s helpline
        ],
        "TR": [ // Turkey
            "Ambulance": "112",
            "Police": "155",
            "Women Helpline": "183" // Women and family helpline
        ],
        "TM": [ // Turkmenistan
            "Ambulance": "03",
            "Police": "02",
            "Women Helpline": "112" // General emergency
        ],
        "TV": [ // Tuvalu
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "999" // General emergency
        ],
        "UG": [ // Uganda
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "116" // Child and women helpline
        ],
        "UA": [ // Ukraine
            "Ambulance": "103",
            "Police": "102",
            "Women Helpline": "116123" // Domestic violence helpline
        ],
        "AE": [ // United Arab Emirates
            "Ambulance": "998",
            "Police": "999",
            "Women Helpline": "800111" // Family and women helpline
        ],
        "GB": [ // United Kingdom
            "Ambulance": "999",
            "Police": "999",
            "Women Helpline": "08082000247" // National Domestic Abuse Helpline
        ],
        "US": [ // United States
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "18007997233" // National Domestic Violence Hotline
        ],
        "UY": [ // Uruguay
            "Ambulance": "105",
            "Police": "911",
            "Women Helpline": "08004141" // Domestic violence helpline
        ],
        "UZ": [ // Uzbekistan
            "Ambulance": "103",
            "Police": "102",
            "Women Helpline": "1146" // Women’s helpline
        ],
        "VU": [ // Vanuatu
            "Ambulance": "112",
            "Police": "112",
            "Women Helpline": "161" // Family violence helpline
        ],
        "VE": [ // Venezuela
            "Ambulance": "911",
            "Police": "911",
            "Women Helpline": "0800-668-4636" // Women’s helpline
        ],
        "VN": [ // Vietnam
            "Ambulance": "115",
            "Police": "113",
            "Women Helpline": "18001567" // National women’s helpline
        ],
        "YE": [ // Yemen
            "Ambulance": "191",
            "Police": "194",
            "Women Helpline": "112" // General emergency
        ],
        "ZM": [ // Zambia
            "Ambulance": "999",
            "Police": "911",
            "Women Helpline": "116" // Child and women helpline
        ],
        "ZW": [ // Zimbabwe
            "Ambulance": "994",
            "Police": "999",
            "Women Helpline": "116" // Child and women helpline
        ]
    ]
    
    // Default country code if detection fails
    private static let defaultCountryCode = "IN"
    
    // Singleton instance
    static let shared = EmergencyNumbersManager()
    
    private var currentCountryCode: String = defaultCountryCode
    
    private init() {}
    
    // Fetch country code from location and update numbers
    func updateCountryCode(from location: CLLocation, completion: @escaping () -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let error = error {
                print("Geocoding failed: \(error.localizedDescription)")
                self.currentCountryCode = Self.defaultCountryCode
            } else if let countryCode = placemarks?.first?.isoCountryCode {
                self.currentCountryCode = countryCode.uppercased()
                print("Country code updated to: \(self.currentCountryCode)")
            }
            completion()
        }
    }
    func getEmergencyNumbers() -> [String: String] {
        return Self.numbersByCountry[currentCountryCode] ?? Self.numbersByCountry[Self.defaultCountryCode]!
    }
}

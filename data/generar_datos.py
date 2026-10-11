"""Generates ICE-Fuente.csv, a synthetic stand-in for the course's original Excel file.

The original export (ICE-Fuente.xls) was not kept, so this script rebuilds a flat,
denormalized table with exactly the columns the 2018 load script reads. Countries,
regions, departments and municipalities are real places (a sample of municipalities
per department); parties, vote counts and demographic splits are invented.

The random generator is seeded, so the file is reproducible:

    python3 data/generar_datos.py > data/ICE-Fuente.csv
"""

import csv
import random
import sys

SEED = 2018

# Column names and order of the Excel sheet, as referenced by cargaabd.sql.
COLUMNS = [
    "PAIS", "NOMBRE_ELECCION", "AÑO_ELECCION", "REGION", "DEPTO", "MUNICIPIO",
    "PARTIDO", "NOMBRE_PARTIDO", "SEXO", "RAZA",
    "ANALFABETOS", "ALFABETOS", "PRIMARIA", "NIVEL MEDIO", "UNIVERSITARIOS",
]

# country -> (election name, year, literacy rate, {region: {department: [municipalities]}})
GEOGRAFIA = {
    "GUATEMALA": ("Elecciones Generales", 2015, 0.81, {
        "Metropolitana": {"Guatemala": ["Guatemala", "Mixco", "Villa Nueva"]},
        "Norte": {"Alta Verapaz": ["Cobán", "San Pedro Carchá"], "Baja Verapaz": ["Salamá", "Rabinal"]},
        "Nororiente": {"Chiquimula": ["Chiquimula", "Esquipulas"], "El Progreso": ["Guastatoya", "Sanarate"],
                       "Izabal": ["Puerto Barrios", "Livingston", "Morales"], "Zacapa": ["Zacapa", "Gualán"]},
        "Suroriente": {"Jutiapa": ["Jutiapa", "Asunción Mita"], "Jalapa": ["Jalapa", "Monjas"],
                       "Santa Rosa": ["Cuilapa", "Barberena"]},
        "Central": {"Chimaltenango": ["Chimaltenango", "Tecpán Guatemala"],
                    "Sacatepéquez": ["Antigua Guatemala", "Ciudad Vieja"],
                    "Escuintla": ["Escuintla", "Santa Lucía Cotzumalguapa"]},
        "Suroccidente": {"Quetzaltenango": ["Quetzaltenango", "Coatepeque"], "Retalhuleu": ["Retalhuleu", "Champerico"],
                         "San Marcos": ["San Marcos", "Malacatán"], "Suchitepéquez": ["Mazatenango", "Chicacao"],
                         "Sololá": ["Sololá", "Panajachel"], "Totonicapán": ["Totonicapán", "Momostenango"]},
        "Noroccidente": {"Huehuetenango": ["Huehuetenango", "Chiantla"],
                         "Quiché": ["Santa Cruz del Quiché", "Chichicastenango"]},
        "Petén": {"Petén": ["Flores", "San Benito"]},
    }),
    "EL SALVADOR": ("Elecciones Presidenciales", 2014, 0.89, {
        "Occidental": {"Ahuachapán": ["Ahuachapán", "Atiquizaya"], "Santa Ana": ["Santa Ana", "Chalchuapa"],
                       "Sonsonate": ["Sonsonate", "Izalco"]},
        "Central": {"Chalatenango": ["Chalatenango", "Nueva Concepción"], "La Libertad": ["Santa Tecla", "Antiguo Cuscatlán"],
                    "San Salvador": ["San Salvador", "Soyapango"], "Cuscatlán": ["Cojutepeque", "Suchitoto"]},
        "Paracentral": {"La Paz": ["Zacatecoluca", "Olocuilta"], "Cabañas": ["Sensuntepeque", "Ilobasco"],
                        "San Vicente": ["San Vicente", "Tecoluca"]},
        "Oriental": {"Usulután": ["Usulután", "Jiquilisco"], "San Miguel": ["San Miguel", "Chinameca"],
                     "Morazán": ["San Francisco Gotera", "Perquín"], "La Unión": ["La Unión", "Santa Rosa de Lima"]},
    }),
    "HONDURAS": ("Elecciones Generales", 2017, 0.87, {
        "Norte": {"Atlántida": ["La Ceiba", "Tela"], "Colón": ["Trujillo", "Tocoa"],
                  "Cortés": ["San Pedro Sula", "Puerto Cortés"], "Yoro": ["Yoro", "El Progreso"],
                  "Islas de la Bahía": ["Roatán", "Utila"]},
        "Occidente": {"Copán": ["Santa Rosa de Copán", "Copán Ruinas"], "Ocotepeque": ["Ocotepeque"],
                      "Lempira": ["Gracias"], "Intibucá": ["La Esperanza"], "Santa Bárbara": ["Santa Bárbara"]},
        "Centro": {"Francisco Morazán": ["Distrito Central", "Valle de Ángeles"],
                   "Comayagua": ["Comayagua", "Siguatepeque"], "La Paz": ["La Paz"]},
        "Oriente": {"El Paraíso": ["Yuscarán", "Danlí"], "Olancho": ["Juticalpa", "Catacamas"],
                    "Gracias a Dios": ["Puerto Lempira"]},
        "Sur": {"Choluteca": ["Choluteca", "Pespire"], "Valle": ["Nacaome", "San Lorenzo"]},
    }),
    "NICARAGUA": ("Elecciones Nacionales", 2016, 0.83, {
        "Pacífico": {"Managua": ["Managua", "Tipitapa"], "León": ["León", "La Paz Centro"],
                     "Chinandega": ["Chinandega", "Corinto"], "Masaya": ["Masaya", "Nindirí"],
                     "Granada": ["Granada"], "Carazo": ["Jinotepe", "Diriamba"], "Rivas": ["Rivas", "San Juan del Sur"]},
        "Central-Norte": {"Estelí": ["Estelí"], "Madriz": ["Somoto"], "Nueva Segovia": ["Ocotal"],
                          "Jinotega": ["Jinotega"], "Matagalpa": ["Matagalpa"], "Boaco": ["Boaco"],
                          "Chontales": ["Juigalpa"]},
        "Caribe": {"Río San Juan": ["San Carlos"], "Costa Caribe Norte": ["Puerto Cabezas"],
                   "Costa Caribe Sur": ["Bluefields"]},
    }),
    "COSTA RICA": ("Elecciones Nacionales", 2018, 0.97, {
        "Central": {"San José": ["San José", "Desamparados"], "Alajuela": ["Alajuela", "San Carlos"],
                    "Cartago": ["Cartago", "Paraíso"], "Heredia": ["Heredia", "Santo Domingo"]},
        "Pacífico": {"Guanacaste": ["Liberia", "Nicoya"], "Puntarenas": ["Puntarenas", "Golfito"]},
        "Caribe": {"Limón": ["Limón", "Talamanca"]},
    }),
    "PANAMA": ("Elecciones Generales", 2014, 0.95, {
        "Occidental": {"Bocas del Toro": ["Changuinola"], "Chiriquí": ["David", "Boquete"], "Veraguas": ["Santiago"]},
        "Central": {"Coclé": ["Penonomé", "Aguadulce"], "Herrera": ["Chitré"], "Los Santos": ["Las Tablas"],
                    "Panamá": ["Panamá", "San Miguelito"], "Panamá Oeste": ["La Chorrera", "Arraiján"],
                    "Colón": ["Colón"]},
        "Oriental": {"Darién": ["Chepigana"]},
    }),
}

# Fictional parties: codes are unique across countries because the load script
# joins votes to parties by code only.
PARTIDOS = {
    "GUATEMALA": [("MCV", "Movimiento Ciudadano Verde"), ("PUN", "Partido Unidad Nacional"),
                  ("ALQ", "Alianza Quetzal"), ("FRD", "Frente Democrático"), ("CRE", "Compromiso y Renovación")],
    "EL SALVADOR": [("PAZ", "Partido Azul"), ("FUC", "Frente de Unidad Cívica"),
                    ("NUS", "Nuevo Salvador"), ("MDC", "Movimiento Democrático Cuscatleco")],
    "HONDURAS": [("PLH", "Partido Libre Hondureño"), ("ACH", "Alianza Ciudadana"),
                 ("PNP", "Partido Nueva Patria"), ("UDH", "Unión Democrática")],
    "NICARAGUA": [("FUN", "Frente de Unidad Nicaragüense"), ("PLN", "Partido Liberal Nuevo"),
                  ("ARN", "Alianza Republicana"), ("MRL", "Movimiento Renovador Lacustre")],
    "COSTA RICA": [("PAC", "Partido Acción Costarricense"), ("PRN", "Partido Restauración Nacional"),
                   ("UNC", "Unidad Nacional Central"), ("FAP", "Frente Amplio Popular")],
    "PANAMA": [("CDP", "Cambio Democrático Panameño"), ("PRP", "Partido Revolucionario del Pueblo"),
               ("PIP", "Partido Istmeño Popular"), ("MOL", "Movimiento Liberal")],
}

# Share of voters per race by place, with defaults per country.
RAZA_PAIS = {
    "GUATEMALA": (0.01, 0.40, 0.59), "EL SALVADOR": (0.005, 0.02, 0.975), "HONDURAS": (0.02, 0.07, 0.91),
    "NICARAGUA": (0.01, 0.06, 0.93), "COSTA RICA": (0.01, 0.025, 0.965), "PANAMA": (0.02, 0.12, 0.86),
}
RAZA_DEPTO = {  # (garífunas, indígenas, ladinos)
    "Totonicapán": (0.0, 0.97, 0.03), "Sololá": (0.0, 0.96, 0.04), "Quiché": (0.0, 0.88, 0.12),
    "Alta Verapaz": (0.0, 0.90, 0.10), "Huehuetenango": (0.0, 0.65, 0.35), "Quetzaltenango": (0.0, 0.52, 0.48),
    "San Marcos": (0.0, 0.31, 0.69), "Chimaltenango": (0.0, 0.78, 0.22), "Baja Verapaz": (0.0, 0.59, 0.41),
    "Suchitepéquez": (0.0, 0.48, 0.52), "Izabal": (0.08, 0.26, 0.66), "Guatemala": (0.0, 0.13, 0.87),
    "Sacatepéquez": (0.0, 0.40, 0.60), "Petén": (0.0, 0.31, 0.69),
    "Atlántida": (0.12, 0.03, 0.85), "Colón": (0.10, 0.04, 0.86), "Islas de la Bahía": (0.20, 0.01, 0.79),
    "Gracias a Dios": (0.15, 0.60, 0.25), "Intibucá": (0.0, 0.55, 0.45), "Lempira": (0.0, 0.45, 0.55),
    "Costa Caribe Norte": (0.03, 0.55, 0.42), "Costa Caribe Sur": (0.08, 0.20, 0.72),
    "Limón": (0.10, 0.08, 0.82), "Bocas del Toro": (0.05, 0.60, 0.35), "Darién": (0.03, 0.45, 0.52),
}
RAZAS = ("GARIFUNAS", "INDIGENAS", "LADINOS")

# Rough number of voters per municipality: big cities get a lot more.
GRANDES = {"Guatemala": 450_000, "Mixco": 220_000, "Villa Nueva": 210_000, "San Salvador": 160_000,
           "San Pedro Sula": 300_000, "Distrito Central": 520_000, "Managua": 480_000, "San José": 160_000,
           "Panamá": 450_000, "San Miguelito": 160_000, "Soyapango": 120_000, "Desamparados": 110_000}


def reparto(rng, total, pesos):
    """Splits an integer total into len(pesos) integers proportional to pesos."""
    suma = sum(pesos)
    partes = [int(total * p / suma) for p in pesos]
    resto = total - sum(partes)
    for i in rng.sample(range(len(pesos)), k=len(pesos))[:resto]:
        partes[i] += 1
    return partes


def generar(rng):
    for pais, (eleccion, anio, alfabetismo, regiones) in GEOGRAFIA.items():
        partidos = PARTIDOS[pais]
        # National mood: each party has a baseline share, perturbed per department.
        base = [rng.uniform(0.6, 1.6) for _ in partidos]
        for region, deptos in regiones.items():
            for depto, municipios in deptos.items():
                depto_pref = [b * rng.uniform(0.6, 1.5) for b in base]
                razas = RAZA_DEPTO.get(depto, RAZA_PAIS[pais])
                # University share by sex varies per department, so in some of them
                # more women than men went to university (query 7).
                univ = {"hombres": rng.uniform(0.08, 0.18), "mujeres": rng.uniform(0.07, 0.19)}
                for i, municipio in enumerate(municipios):
                    votantes = GRANDES.get(municipio, rng.randint(9_000, 60_000) * (2 if i == 0 else 1))
                    pref = [p * rng.uniform(0.7, 1.4) for p in depto_pref]
                    por_partido = reparto(rng, votantes, pref)
                    for (codigo, nombre), votos_partido in zip(partidos, por_partido):
                        por_sexo = reparto(rng, votos_partido, [rng.uniform(0.47, 0.53), rng.uniform(0.47, 0.53)])
                        for sexo, votos_sexo in zip(("hombres", "mujeres"), por_sexo):
                            por_raza = reparto(rng, votos_sexo, [max(r, 0.0001) * rng.uniform(0.8, 1.2) for r in razas])
                            for raza, n in zip(RAZAS, por_raza):
                                if n == 0:
                                    continue
                                tasa = alfabetismo * (0.85 if raza == "INDIGENAS" else 1.0) * rng.uniform(0.95, 1.03)
                                alfabetos = min(n, round(n * tasa))
                                analfabetos = n - alfabetos
                                u = univ[sexo] * (0.5 if raza == "INDIGENAS" else 1.0)
                                medio = rng.uniform(0.25, 0.35)
                                primaria, nivel_medio, universitarios = reparto(rng, alfabetos, [1 - u - medio, medio, u])
                                yield [pais, eleccion, anio, region, depto, municipio, codigo, nombre, sexo, raza,
                                       analfabetos, alfabetos, primaria, nivel_medio, universitarios]


def main():
    writer = csv.writer(sys.stdout, lineterminator="\n")
    writer.writerow(COLUMNS)
    for fila in generar(random.Random(SEED)):
        writer.writerow(fila)


if __name__ == "__main__":
    main()

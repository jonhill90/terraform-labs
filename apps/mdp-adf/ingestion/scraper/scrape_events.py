

import os
import json
import re
import cloudscraper
from bs4 import BeautifulSoup
from azure.storage.blob import BlobServiceClient

EVENT_PAGES = [
    "Bilbo's_Farewell_Party", "Christmas", "Cormarë", "Eruhantalë", "Erukyermë", "Erulaitalë", "Feast_of_Felling",
    "Free_Fair", "Gates_of_Summer", "Great_Bear-dance", "High_feast", "Mereth_Aderthad", "Nost-na-Lothion",
    "Standing_Silence", "Three_Prayers", "Turuhalmë", "Yule", "Axan", "Dagor_Dagorath", "Doom_of_Mandos",
    "Galadriel's_messages", "Oath_of_Elendil", "Oath_of_Eorl", "Oath_of_Fëanor", "Old_Hope",
    "Over_the_land_there_lies_a_long_shadow", "Statute_of_Finwë_and_Míriel", "Ulmo's_warning",
    "Battle_in_the_Thousand_Caves", "Battle_of_Palisor", "Battle_of_Rôs", "Battle_of_Sarn_Athrad",
    "Battle_of_Tasarinan", "Battle_of_the_Heath_of_the_Sky-roof", "Battle_of_the_Powers", "Battle_of_the_Silent_Pools",
    "Battle_of_Tumhalad", "Fall_of_Gondolin", "Fall_of_Nargothrond", "Faring_Forth", "Kinslaying_at_Alqualondë",
    "Nirnaeth_Arnoediad", "Second_Kinslaying", "Third_Kinslaying", "War_of_Wrath", "Assaults_on_Hithlum",
    "Battle_of_Eglarest", "Battle_of_the_Gelion-Ascar_stockade", "Battle_of_the_Lammoth", "Battle_of_the_Pass_of_Aglon",
    "Battles_of_Beleriand", "Dagor_Aglareb", "Dagor_Bragollach", "Dagor-nuin-Giliath", "Downfall_of_Angband",
    "Fall_of_Fingolfin", "Fall_of_the_Falas", "First_Battle", "Massacre_at_Tarn_Aeluin", "Ruin_of_Beleriand",
    "Sack_of_Bar-en-Danwedh", "Siege_of_Angband", "Anárion's_defence_of_Osgiliath", "Battle_of_Dagorlad",
    "Battle_of_the_Gwathló", "Fall_of_Mount_Gundabad", "First_Fall_of_Minas_Ithil", "First_Siege_of_Imladris",
    "Sack_of_Eregion", "Siege_of_Barad-dûr", "War_of_the_Elves_and_Sauron", "War_of_the_Last_Alliance",
    "Battle_of_Fornost", "Fall_of_Amon_Sûl", "Fall_of_Cardolan", "Fall_of_Fornost", "Second_siege_of_Imladris",
    "Ambush_at_Fangorn_Forest", "Assaults_on_Lothlórien", "Battle_of_Bywater", "Battle_of_Dale",
    "Battle_of_Isengard", "Battle_of_the_Chamber_of_Mazarbul", "Battle_of_the_Hornburg", "Battle_of_the_Morannon",
    "Battle_of_the_Pelennor_Fields", "Battle_under_the_trees", "Battles_of_the_Fords_of_Isen",
    "Breaking_of_the_Fellowship", "Fall_of_Dol_Guldur", "Faramir's_defence_of_Osgiliath",
    "First_Battle_of_the_Fords_of_Isen", "Sauron's_attack_on_Osgiliath", "Second_Battle_of_the_Fords_of_Isen",
    "Siege_of_Gondor", "Angmar_conflict", "Attack_on_Dol_Guldur", "Battle_of_Azanulbizar",
    "Battle_of_Cirith_Ungol", "Battle_of_Five_Armies", "Battle_of_Greenfields", "Battle_of_the_Camp",
    "Battle_of_the_Crossings_of_Erui", "Battle_of_the_Crossings_of_Poros", "Battle_of_the_Field_of_Celebrant",
    "Battle_of_the_Peak", "Battle_of_the_Second_Hall", "Burning_of_Osgiliath", "Corsair_wars",
    "Disaster_of_the_Gladden_Fields", "Disaster_of_the_Morannon", "Kin-strife", "Last_stand_of_Balin's_folk",
    "Ruin_of_Osgiliath", "Sack_of_Erebor", "Sacking_of_Mount_Gundabad", "Second_battle_of_Dagorlad",
    "Second_Fall_of_Minas_Ithil", "Surprise_attack_on_Umbar", "Wainrider/Balchoth_War",
    "War_of_the_Dwarves_and_Dragons", "War_of_the_Dwarves_and_Orcs", "War_of_the_Ring", "Falas",
    "Minas_Morgul", "Pelargir", "Siege_of_Pelargir", "Siege_of_Utumno", "First_War", "Great_Siege"
]

def upload_to_blob(data, blob_name):
    connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
    if not connection_string:
        raise Exception("Missing AZURE_STORAGE_CONNECTION_STRING environment variable.")
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client("lotr-data")
    blob_client = container_client.get_blob_client(blob_name)
    blob_client.upload_blob(json.dumps(data, indent=2, ensure_ascii=False), overwrite=True)
    print(f"Uploaded {blob_name} to Azure Blob Storage.")

def extract_description(soup):
    p = soup.find("p")
    if p:
        return p.get_text(strip=True)
    return ""

def detect_type(name):
    name = name.lower()
    if "battle" in name:
        return "battle"
    if "siege" in name:
        return "siege"
    if "council" in name:
        return "event"
    if "day" in name:
        return "event"
    return "event"

def scrape_event(name):
    api_url = "https://tolkiengateway.net/w/api.php"
    params = {
        "action": "parse",
        "page": name,
        "prop": "text",
        "format": "json",
        "formatversion": "2",
        "origin": "*"
    }

    scraper = cloudscraper.create_scraper()
    response = scraper.get(api_url, params=params)
    try:
        data_json = response.json()
    except Exception as e:
        print(f"Error scraping {name}: {e}")
        return {}

    html = data_json.get("parse", {}).get("text", "")
    soup = BeautifulSoup(html, "lxml")

    data = {
        "name": name.replace("_", " "),
        "source": f"https://tolkiengateway.net/wiki/{name}",
        "type": detect_type(name),
        "description": extract_description(soup)
    }

    for row in soup.find_all("tr"):
        th = row.find("th", class_="tg-infobox-label")
        td = row.find("td", class_="tg-infobox-data")
        if th and td:
            key = th.get_text(strip=True).lower().replace(" ", "_")
            value = ' '.join(td.stripped_strings)
            data[key] = value

    return data

def main():
    for event in EVENT_PAGES:
        event_data = scrape_event(event)
        if event_data:
            blob_name = f"events/{event.replace(' ', '_')}.json"
            upload_to_blob(event_data, blob_name)

if __name__ == "__main__":
    main()
"""Baixa as fotos dos itens a partir da Wikipedia / Wikimedia Commons.

Usa so imagens com licenca livre (filtro pilicense=free da Wikipedia, mais a
licenca conferida no Commons) e grava os creditos (autor, licenca, link) em
assets/fotos/creditos.json, mostrados na tela de Configuracoes > Creditos.

Uso: python3 tool/baixar_fotos.py   (requer Pillow e acesso a wikipedia/wikimedia)
Gera tambem lib/data/fotos_data.dart com o mapa item -> arquivo.
"""
import io
import json
import os
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request

from PIL import Image, ImageOps

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SAIDA = os.path.join(RAIZ, 'assets', 'fotos')
UA = 'LanceGameAssets/1.0 (offline party game build script)'
TAM = 320

# Titulo do artigo na Wikipedia em ingles para cada item (quando difere do nome).
TITULOS = {
    # Futebol
    'Pelé': 'Pelé', 'Neymar': 'Neymar', 'Messi': 'Lionel Messi', 'Cristiano Ronaldo': 'Cristiano Ronaldo',
    'Mbappé': 'Kylian Mbappé', 'Haaland': 'Erling Haaland', 'Vinícius Jr.': 'Vinícius Júnior',
    'Ronaldinho': 'Ronaldinho', 'Ronaldo Fenômeno': 'Ronaldo (Brazilian footballer)', 'Zico': 'Zico (footballer)',
    'Romário': 'Romário', 'Kaká': 'Kaká', 'Rivaldo': 'Rivaldo', 'Zidane': 'Zinedine Zidane',
    'Maradona': 'Diego Maradona', 'Cruyff': 'Johan Cruyff', 'Beckenbauer': 'Franz Beckenbauer',
    'Modric': 'Luka Modrić', 'Lewandowski': 'Robert Lewandowski', 'Salah': 'Mohamed Salah',
    'De Bruyne': 'Kevin De Bruyne', 'Benzema': 'Karim Benzema', 'Iniesta': 'Andrés Iniesta',
    'Xavi': 'Xavi', 'Casillas': 'Iker Casillas', 'Buffon': 'Gianluigi Buffon', 'Neuer': 'Manuel Neuer',
    'Alisson': 'Alisson Becker', 'Marcelo': 'Marcelo (footballer, born 1988)', 'Roberto Carlos': 'Roberto Carlos',
    'Cafu': 'Cafu', 'Thiago Silva': 'Thiago Silva', 'Casemiro': 'Casemiro', 'Rodri': 'Rodri (footballer, born 1996)',
    'Bellingham': 'Jude Bellingham', 'Harry Kane': 'Harry Kane', 'Griezmann': 'Antoine Griezmann',
    'Luis Suárez': 'Luis Suárez', 'Ibrahimovic': 'Zlatan Ibrahimović', 'Thierry Henry': 'Thierry Henry',
    'Raphinha': 'Raphinha', 'Endrick': 'Endrick (footballer)', 'Garrincha': 'Garrincha', 'Sócrates': 'Sócrates (footballer)',
    'Bebeto': 'Bebeto', 'Pedri': 'Pedri', 'Lamine Yamal': 'Lamine Yamal', 'Gavi': 'Gavi (footballer)',
    # Comidas
    'Pizza': 'Pizza', 'Hambúrguer': 'Hamburger', 'Lasanha': 'Lasagna', 'Feijoada': 'Feijoada', 'Sushi': 'Sushi',
    'Churrasco': 'Churrasco', 'Coxinha': 'Coxinha', 'Pastel': 'Pastel (food)', 'Pão de queijo': 'Pão de queijo',
    'Brigadeiro': 'Brigadeiro', 'Açaí': 'Açaí na tigela', 'Tapioca': 'Beiju', 'Acarajé': 'Acarajé',
    'Moqueca': 'Moqueca', 'Strogonoff': 'Beef Stroganoff', 'Batata frita': 'French fries', 'Cachorro-quente': 'Hot dog',
    'Taco': 'Taco', 'Burrito': 'Burrito', 'Ramen': 'Ramen', 'Macarrão à bolonhesa': 'Spaghetti alla bolognese',
    'Risoto': 'Risotto', 'Paella': 'Paella', 'Picanha': 'Picanha', 'Frango assado': 'Roast chicken',
    'Escondidinho': 'Escondidinho', 'Arroz com feijão': 'Rice and beans', 'Farofa': 'Farofa', 'Esfiha': 'Sfiha',
    'Kibe': 'Kibbeh', 'Empada': 'Empanada', 'Bolo de chocolate': 'Chocolate cake', 'Pudim': 'Flan',
    'Sorvete': 'Ice cream', 'Panqueca': 'Pancake', 'Waffle': 'Waffle', 'Crepe': 'Crêpe', 'Omelete': 'Omelette',
    'Salada Caesar': 'Caesar salad', 'Nhoque': 'Gnocchi', 'Baião de dois': 'Baião de dois', 'Vatapá': 'Vatapá',
    'Galinhada': 'Galinhada', 'Pamonha': 'Pamonha', 'Cuscuz': 'Cuscuz', 'Mousse de maracujá': 'Mousse',
    'Torta de limão': 'Lemon meringue pie', 'Churros': 'Churro', 'Pipoca': 'Popcorn', 'Parmegiana': 'Parmigiana',
    # Bebidas
    'Coca-Cola': 'Coca-Cola', 'Guaraná': 'Guaraná Antarctica', 'Suco de laranja': 'Orange juice',
    'Caipirinha': 'Caipirinha', 'Cerveja': 'Beer', 'Vinho tinto': 'Red wine', 'Champanhe': 'Champagne',
    'Café expresso': 'Espresso', 'Cappuccino': 'Cappuccino', 'Chá gelado': 'Iced tea', 'Água de coco': 'Coconut water',
    'Limonada': 'Lemonade', 'Milkshake': 'Milkshake', 'Chocolate quente': 'Hot chocolate', 'Mate': 'Mate (drink)',
    'Chimarrão': 'Chimarrão', 'Tereré': 'Tereré', 'Energético': 'Energy drink', 'Vitamina de banana': 'Smoothie',
    'Smoothie de morango': 'Smoothie', 'Mojito': 'Mojito', 'Margarita': 'Margarita', 'Piña Colada': 'Piña colada',
    'Gin tônica': 'Gin and tonic', 'Whisky': 'Whisky', 'Vodka': 'Vodka', 'Tequila': 'Tequila', 'Cachaça': 'Cachaça',
    'Saquê': 'Sake', 'Kombucha': 'Kombucha', 'Caldo de cana': 'Sugarcane juice', 'Suco de uva': 'Grape juice',
    'Suco de maracujá': 'Passion fruit juice', 'Água com gás': 'Carbonated water', 'Refrigerante de laranja': 'Fanta',
    'Chá verde': 'Green tea', 'Chá de camomila': 'Chamomile', 'Café gelado': 'Iced coffee', 'Frappuccino': 'Frappuccino',
    'Achocolatado': 'Chocolate milk', 'Iogurte de morango': 'Yogurt', 'Bubble tea': 'Bubble tea', 'Sangria': 'Sangria',
    'Aperol Spritz': 'Spritz (drink)', 'Quentão': 'Quentão', 'Vinho quente': 'Mulled wine', 'Sidra': 'Cider',
    'Licor de chocolate': 'Chocolate liqueur', 'Suco detox': 'Green juice', 'Isotônico': 'Sports drink',
    # Aplicativos
    'WhatsApp': 'WhatsApp', 'Instagram': 'Instagram', 'TikTok': 'TikTok', 'YouTube': 'YouTube', 'Spotify': 'Spotify',
    'Netflix': 'Netflix', 'Uber': 'Uber', 'iFood': 'iFood', 'Google Maps': 'Google Maps', 'Waze': 'Waze',
    'Facebook': 'Facebook', 'X (Twitter)': 'Twitter', 'Telegram': 'Telegram (software)', 'Discord': 'Discord',
    'Pinterest': 'Pinterest', 'LinkedIn': 'LinkedIn', 'Snapchat': 'Snapchat', 'Twitch': 'Twitch (service)',
    'Duolingo': 'Duolingo', 'Shazam': 'Shazam (application)', 'Nubank': 'Nubank', 'Mercado Livre': 'Mercado Libre',
    'Amazon': 'Amazon (company)', 'Shopee': 'Shopee', 'AliExpress': 'AliExpress', 'Airbnb': 'Airbnb',
    'Booking': 'Booking.com', '99': '99 (app)', 'Rappi': 'Rappi', 'Zoom': 'Zoom Workplace', 'Google Meet': 'Google Meet',
    'Gmail': 'Gmail', 'Google Drive': 'Google Drive', 'Dropbox': 'Dropbox', 'Canva': 'Canva', 'CapCut': 'CapCut',
    'Kindle': 'Amazon Kindle', 'Strava': 'Strava', 'Tinder': 'Tinder (app)', 'Picsart': 'Picsart',
    'Disney+': 'Disney+', 'Prime Video': 'Amazon Prime Video', 'Max': 'Max (streaming service)', 'Globoplay': 'Globoplay',
    'Deezer': 'Deezer', 'ChatGPT': 'ChatGPT', 'Threads': 'Threads (social network)', 'Reddit': 'Reddit',
    'Steam': 'Steam (service)', 'Roblox': 'Roblox',
    # Carros
    'Fusca': 'Volkswagen Beetle', 'Ferrari F40': 'Ferrari F40', 'Lamborghini Aventador': 'Lamborghini Aventador',
    'Porsche 911': 'Porsche 911', 'Tesla Model S': 'Tesla Model S', 'Chevrolet Camaro': 'Chevrolet Camaro',
    'Ford Mustang': 'Ford Mustang', 'Dodge Charger': 'Dodge Charger', 'Toyota Corolla': 'Toyota Corolla',
    'Honda Civic': 'Honda Civic', 'Volkswagen Gol': 'Volkswagen Gol', 'Fiat Uno': 'Fiat Uno', 'Fiat Palio': 'Fiat Palio',
    'Chevrolet Onix': 'Chevrolet Onix', 'Jeep Renegade': 'Jeep Renegade', 'Toyota Hilux': 'Toyota Hilux',
    'Ford Ranger': 'Ford Ranger', 'BMW M3': 'BMW M3', 'Mercedes-AMG GT': 'Mercedes-AMG GT', 'Audi R8': 'Audi R8',
    'McLaren P1': 'McLaren P1', 'Bugatti Chiron': 'Bugatti Chiron', 'Koenigsegg Jesko': 'Koenigsegg Jesko',
    'Nissan GT-R': 'Nissan GT-R', 'Mitsubishi Lancer Evolution': 'Mitsubishi Lancer Evolution',
    'Subaru Impreza WRX': 'Subaru Impreza WRX', 'Mazda MX-5': 'Mazda MX-5', 'Volkswagen Golf GTI': 'Volkswagen Golf GTI',
    'Mini Cooper': 'Mini (marque)', 'Fiat 500': 'Fiat 500 (2007)', 'Kombi': 'Volkswagen Type 2',
    'Chevrolet Opala': 'Chevrolet Opala', 'Ford Maverick': 'Ford Maverick (1970–1977)', 'Volkswagen Brasília': 'Volkswagen Brasília',
    'Gurgel BR-800': 'Gurgel BR-800', 'Land Rover Defender': 'Land Rover Defender', 'Range Rover': 'Range Rover',
    'Toyota Supra': 'Toyota Supra', 'Honda NSX': 'Honda NSX', 'Aston Martin DB5': 'Aston Martin DB5',
    'Rolls-Royce Phantom': 'Rolls-Royce Phantom', 'Bentley Continental': 'Bentley Continental GT',
    'Maserati MC20': 'Maserati MC20', 'Alfa Romeo Giulia': 'Alfa Romeo Giulia (952)', 'Volvo XC90': 'Volvo XC90',
    'Hyundai HB20': 'Hyundai HB20', 'Renault Kwid': 'Renault Kwid', 'BYD Dolphin': 'BYD Dolphin',
    'Jeep Wrangler': 'Jeep Wrangler', 'Chevrolet Corvette': 'Chevrolet Corvette',
    # Marcas
    'Nike': 'Nike, Inc.', 'Adidas': 'Adidas', 'Apple': 'Apple Inc.', 'Samsung': 'Samsung', "McDonald's": "McDonald's",
    'Google': 'Google', 'Microsoft': 'Microsoft', 'Disney': 'The Walt Disney Company', 'Lego': 'Lego', 'Puma': 'Puma (brand)',
    'Havaianas': 'Havaianas', 'Natura': 'Natura &Co', 'O Boticário': 'O Boticário', 'Nestlé': 'Nestlé', 'Lacta': 'Lacta',
    'Garoto': 'Chocolates Garoto', 'Sadia': 'Sadia', 'Itaú': 'Itaú Unibanco', 'Magalu': 'Magazine Luiza',
    'Casas Bahia': 'Casas Bahia', 'Renner': 'Lojas Renner', 'Gucci': 'Gucci', 'Louis Vuitton': 'Louis Vuitton',
    'Chanel': 'Chanel', 'Rolex': 'Rolex', 'Ray-Ban': 'Ray-Ban', 'Vans': 'Vans', 'Converse': 'Converse (shoe company)',
    'Red Bull': 'Red Bull', 'Heineken': 'Heineken', 'Toyota': 'Toyota', 'Volkswagen': 'Volkswagen', 'Ferrari': 'Ferrari',
    'Sony': 'Sony', 'Nintendo': 'Nintendo', 'PlayStation': 'PlayStation', 'Xbox': 'Xbox', 'Starbucks': 'Starbucks',
    'Burger King': 'Burger King', 'KFC': 'KFC', 'Subway': 'Subway (restaurant)', 'Zara': 'Zara (retailer)',
    'Petrobras': 'Petrobras', 'Embraer': 'Embraer',
    # Filmes e series
    'Titanic': 'Titanic (1997 film)', 'Avatar': 'Avatar (2009 film)', 'O Poderoso Chefão': 'The Godfather',
    'Star Wars': 'Star Wars', 'Harry Potter': 'Harry Potter', 'O Senhor dos Anéis': 'The Lord of the Rings (film series)',
    'Vingadores: Ultimato': 'Avengers: Endgame', 'Homem-Aranha': 'Spider-Man', 'Batman: O Cavaleiro das Trevas': 'The Dark Knight',
    'Matrix': 'The Matrix', 'Jurassic Park': 'Jurassic Park (film)', 'De Volta para o Futuro': 'Back to the Future',
    'Toy Story': 'Toy Story', 'O Rei Leão': 'The Lion King', 'Frozen': 'Frozen (2013 film)', 'Procurando Nemo': 'Finding Nemo',
    'Shrek': 'Shrek', 'Cidade de Deus': 'City of God (2002 film)', 'Tropa de Elite': 'Elite Squad',
    'Central do Brasil': 'Central Station (film)', 'O Auto da Compadecida': 'A Dog\'s Will',
    'Interestelar': 'Interstellar (film)', 'A Origem': 'Inception', 'Pulp Fiction': 'Pulp Fiction',
    'Forrest Gump': 'Forrest Gump', 'Gladiador': 'Gladiator (2000 film)', 'Breaking Bad': 'Breaking Bad',
    'Game of Thrones': 'Game of Thrones', 'Friends': 'Friends', 'Stranger Things': 'Stranger Things',
    'La Casa de Papel': 'Money Heist', 'The Office': 'The Office (American TV series)', 'Round 6': 'Squid Game',
    'The Crown': 'The Crown (TV series)', 'The Last of Us': 'The Last of Us (TV series)', 'Wandinha': 'Wednesday (TV series)',
    'Dark': 'Dark (TV series)', 'Peaky Blinders': 'Peaky Blinders (TV series)', 'Os Simpsons': 'The Simpsons',
    'Chaves': 'El Chavo del Ocho', 'Sex Education': 'Sex Education (TV series)', "Grey's Anatomy": "Grey's Anatomy",
    'The Walking Dead': 'The Walking Dead (TV series)', 'Bridgerton': 'Bridgerton', 'Barbie': 'Barbie (film)',
    'Oppenheimer': 'Oppenheimer (film)', 'Divertida Mente': 'Inside Out (2015 film)', 'Coringa': 'Joker (2019 film)',
    'Duna': 'Dune (2021 film)', 'Top Gun: Maverick': 'Top Gun: Maverick',
    # Animais
    'Leão': 'Lion', 'Tigre': 'Tiger', 'Elefante': 'Elephant', 'Girafa': 'Giraffe', 'Zebra': 'Zebra', 'Onça-pintada': 'Jaguar',
    'Lobo-guará': 'Maned wolf', 'Capivara': 'Capybara', 'Tamanduá': 'Giant anteater', 'Bicho-preguiça': 'Sloth',
    'Arara-azul': 'Hyacinth macaw', 'Tucano': 'Toco toucan', 'Papagaio': 'Parrot', 'Golfinho': 'Bottlenose dolphin',
    'Baleia-azul': 'Blue whale', 'Tubarão-branco': 'Great white shark', 'Polvo': 'Octopus', 'Pinguim': 'Penguin',
    'Urso-polar': 'Polar bear', 'Panda': 'Giant panda', 'Coala': 'Koala', 'Canguru': 'Kangaroo', 'Gorila': 'Gorilla',
    'Chimpanzé': 'Chimpanzee', 'Cachorro': 'Dog', 'Gato': 'Cat', 'Cavalo': 'Horse', 'Águia': 'Golden eagle', 'Coruja': 'Owl',
    'Falcão': 'Peregrine falcon', 'Jacaré': 'Yacare caiman', 'Crocodilo': 'Crocodile', 'Cobra-coral': 'Coral snake',
    'Sucuri': 'Green anaconda', 'Camaleão': 'Chameleon', 'Tartaruga': 'Turtle', 'Rinoceronte': 'Rhinoceros',
    'Hipopótamo': 'Hippopotamus', 'Camelo': 'Camel', 'Flamingo': 'Flamingo', 'Raposa': 'Red fox', 'Esquilo': 'Squirrel',
    'Coelho': 'Rabbit', 'Ornitorrinco': 'Platypus', 'Mico-leão-dourado': 'Golden lion tamarin',
    'Boto-cor-de-rosa': 'Amazon river dolphin', 'Tatu': 'Armadillo', 'Peixe-palhaço': 'Clownfish',
    'Borboleta-azul': 'Morpho', 'Lhama': 'Llama',
}

# Itens acrescentados na versao 2.
TITULOS.update({
 "Cássio": "Cássio Ramos",
 "Weverton": "Weverton (footballer, born 1987)",
 "Ederson": "Ederson (footballer, born 1993)",
 "Rogério Ceni": "Rogério Ceni",
 "Taffarel": "Cláudio Taffarel",
 "Dida": "Dida (footballer, born 1973)",
 "Marcos": "Marcos (footballer, born 1973)",
 "Júlio César": "Júlio César (footballer, born 1979)",
 "Fábio": "Fábio (footballer, born 1980)",
 "Hugo Souza": "Hugo Souza",
 "Rossi": "Agustín Rossi",
 "Courtois": "Thibaut Courtois",
 "Oblak": "Jan Oblak",
 "Ter Stegen": "Marc-André ter Stegen",
 "Donnarumma": "Gianluigi Donnarumma",
 "Dibu Martínez": "Emiliano Martínez",
 "Ochoa": "Guillermo Ochoa",
 "Bento": "Bento (footballer)",
 "Everson": "Everson (footballer)",
 "Yashin": "Lev Yashin",
 "Navas": "Keylor Navas",
 "De Gea": "David de Gea",
 "Raya": "David Raya",
 "Sommer": "Yann Sommer",
 "Lúcio": "Lúcio",
 "Juan": "Juan (footballer, born 1979)",
 "Maicon": "Maicon (footballer, born 1981)",
 "Daniel Alves": "Dani Alves",
 "Filipe Luís": "Filipe Luís",
 "David Luiz": "David Luiz",
 "Marquinhos": "Marquinhos (footballer, born 1994)",
 "Militão": "Éder Militão",
 "Bremer": "Gleison Bremer",
 "Danilo": "Danilo (footballer, born 1991)",
 "Alex Sandro": "Alex Sandro",
 "Felipe Melo": "Felipe Melo",
 "Fernandinho": "Fernandinho (footballer, born 1985)",
 "Dunga": "Dunga",
 "Mauro Silva": "Mauro Silva",
 "Gilberto Silva": "Gilberto Silva",
 "Van Dijk": "Virgil van Dijk",
 "Sergio Ramos": "Sergio Ramos",
 "Puyol": "Carles Puyol",
 "Maldini": "Paolo Maldini",
 "Pepe": "Pepe (footballer, born 1983)",
 "Piqué": "Gerard Piqué",
 "Kanté": "N'Golo Kanté",
 "Gattuso": "Gennaro Gattuso",
 "Oscar": "Oscar (footballer, born 1991)",
 "Willian": "Willian (footballer, born 1988)",
 "Lucas Moura": "Lucas Moura",
 "Philippe Coutinho": "Philippe Coutinho",
 "Ganso": "Paulo Henrique Ganso",
 "Arrascaeta": "Giorgian de Arrascaeta",
 "Hernanes": "Hernanes",
 "Renato Augusto": "Renato Augusto",
 "Elias": "Elias (footballer, born 1985)",
 "Paulinho": "Paulinho (footballer, born 1988)",
 "Thiago Neves": "Thiago Neves",
 "Pirlo": "Andrea Pirlo",
 "Kroos": "Toni Kroos",
 "Bruno Fernandes": "Bruno Fernandes",
 "Ødegaard": "Martin Ødegaard",
 "Valderrama": "Carlos Valderrama",
 "Richarlison": "Richarlison",
 "Gabriel Jesus": "Gabriel Jesus",
 "Firmino": "Roberto Firmino",
 "Gabigol": "Gabriel Barbosa",
 "Pedro": "Pedro (footballer, born 1997)",
 "Hulk": "Hulk (footballer)",
 "Fred": "Fred (footballer, born 1983)",
 "Jô": "Jô (footballer)",
 "Grafite": "Grafite",
 "Obina": "Obina",
 "Adriano Imperador": "Adriano (footballer, born 1982)",
 "Robinho": "Robinho",
 "Luís Fabiano": "Luís Fabiano",
 "Edílson": "Edílson (footballer, born 1971)",
 "Dudu": "Dudu (footballer, born 1992)",
 "Bruno Henrique": "Bruno Henrique (footballer, born 1990)",
 "Germán Cano": "Germán Cano",
 "Calleri": "Jonathan Calleri",
 "Deyverson": "Deyverson",
 "Douglas Costa": "Douglas Costa",
 "Rodrygo": "Rodrygo",
 "Vampeta": "Vampeta",
 "Diego Souza": "Diego Souza (footballer, born 1985)",
 "Washington": "Washington (footballer, born 1975)",
 "Yakisoba": "Yakisoba",
 "Temaki": "Temaki",
 "Frango xadrez": "Kung Pao chicken",
 "Misto quente": "Ham and cheese sandwich",
 "X-tudo": "Cheeseburger",
 "Bobó de camarão": "Bobó de camarão",
 "Tacacá": "Tacacá",
 "Arroz carreteiro": "Arroz carreteiro",
 "Feijão tropeiro": "Feijão tropeiro",
 "Torresmo": "Chicharrón",
 "Mandioca frita": "Cassava fries",
 "Polenta frita": "Polenta",
 "Quindim": "Quindim",
 "Beijinho": "Beijinho",
 "Cocada": "Cocada",
 "Paçoca": "Paçoca",
 "Pé de moleque": "Pé-de-moleque",
 "Canjica": "Canjica",
 "Arroz doce": "Rice pudding",
 "Bolo de cenoura": "Carrot cake",
 "Brownie": "Chocolate brownie",
 "Cheesecake": "Cheesecake",
 "Tiramisù": "Tiramisu",
 "Donut": "Doughnut",
 "Croissant": "Croissant",
 "Macaron": "Macaron",
 "Falafel": "Falafel",
 "Kebab": "Doner kebab",
 "Homus": "Hummus",
 "Guacamole": "Guacamole",
 "Ceviche": "Ceviche",
 "Fondue": "Fondue",
 "Nachos": "Nachos",
 "Pão francês": "Pão francês",
 "Coxa de frango": "Fried chicken",
 "Pepsi": "Pepsi",
 "Sprite": "Sprite (drink)",
 "Água tônica": "Tonic water",
 "Kefir": "Kefir",
 "Café com leite": "Café au lait",
 "Latte": "Latte",
 "Mocha": "Caffè mocha",
 "Affogato": "Affogato",
 "Leite": "Milk",
 "Suco de abacaxi": "Pineapple juice",
 "Suco de melancia": "Watermelon juice",
 "Suco de acerola": "Malpighia emarginata",
 "Cuba libre": "Rum and Coke",
 "Moscow mule": "Moscow mule",
 "Negroni": "Negroni",
 "Bloody Mary": "Bloody Mary (cocktail)",
 "Martini": "Martini (cocktail)",
 "Cosmopolitan": "Cosmopolitan (cocktail)",
 "Daiquiri": "Daiquiri",
 "Batida de coco": "Batida",
 "Rum": "Rum",
 "Gin": "Gin",
 "Absinto": "Absinthe",
 "Vinho branco": "White wine",
 "Vinho rosé": "Rosé",
 "Prosecco": "Prosecco",
 "Chopp": "Draught beer",
 "Cerveja preta": "Stout",
 "Matchá": "Matcha",
 "Chá preto": "Black tea",
 "Google Chrome": "Google Chrome",
 "Safari": "Safari (web browser)",
 "Firefox": "Firefox",
 "Microsoft Teams": "Microsoft Teams",
 "Outlook": "Microsoft Outlook",
 "Word": "Microsoft Word",
 "Excel": "Microsoft Excel",
 "PowerPoint": "Microsoft PowerPoint",
 "Google Tradutor": "Google Translate",
 "Google Fotos": "Google Photos",
 "Signal": "Signal (software)",
 "Messenger": "Messenger (software)",
 "Skype": "Skype",
 "Kwai": "Kwai (app)",
 "Clash Royale": "Clash Royale",
 "Candy Crush": "Candy Crush Saga",
 "Free Fire": "Free Fire (video game)",
 "Minecraft": "Minecraft",
 "Fortnite": "Fortnite",
 "Among Us": "Among Us",
 "Pokémon GO": "Pokémon Go",
 "Subway Surfers": "Subway Surfers",
 "PicPay": "PicPay",
 "Mercado Pago": "Mercado Pago",
 "OLX": "OLX",
 "Temu": "Temu",
 "Apple Music": "Apple Music",
 "SoundCloud": "SoundCloud",
 "Wikipedia": "Wikipedia",
 "Gov.br": "Gov.br",
 "Ferrari LaFerrari": "LaFerrari",
 "Lamborghini Huracán": "Lamborghini Huracán",
 "Lamborghini Urus": "Lamborghini Urus",
 "Porsche Cayenne": "Porsche Cayenne",
 "BMW X5": "BMW X5",
 "Mercedes-Benz Classe G": "Mercedes-Benz G-Class",
 "Fiat Strada": "Fiat Strada",
 "Fiat Toro": "Fiat Toro",
 "Volkswagen Polo": "Volkswagen Polo",
 "Volkswagen Saveiro": "Volkswagen Saveiro",
 "Chevrolet S10": "Chevrolet S-10 (Brazil)",
 "Chevrolet Celta": "Chevrolet Celta",
 "Chevrolet Monza": "Chevrolet Monza (Brazil)",
 "Chevrolet Chevette": "Chevrolet Chevette",
 "Ford Ka": "Ford Ka",
 "Ford Fiesta": "Ford Fiesta",
 "Ford F-150": "Ford F-150",
 "Toyota Prius": "Toyota Prius",
 "Toyota Land Cruiser": "Toyota Land Cruiser",
 "Honda Fit": "Honda Fit",
 "Hyundai Creta": "Hyundai Creta",
 "Renault Sandero": "Dacia Sandero",
 "Peugeot 208": "Peugeot 208",
 "Citroën C3": "Citroën C3",
 "Kia Sportage": "Kia Sportage",
 "Nissan Kicks": "Nissan Kicks",
 "Jeep Compass": "Jeep Compass",
 "DeLorean": "DMC DeLorean",
 "Ford Modelo T": "Ford Model T",
 "Fiat 147": "Fiat 147",
 "Volkswagen Santana": "Volkswagen Santana",
 "Fiat Marea": "Fiat Marea",
 "Colgate": "Colgate (toothpaste)",
 "Nivea": "Nivea",
 "Kinder": "Kinder (brand)",
 "Oreo": "Oreo",
 "Doritos": "Doritos",
 "Pringles": "Pringles",
 "Nescau": "Nescau",
 "Omo": "Omo (brand)",
 "Brahma": "Brahma beer",
 "Skol": "Skol",
 "Intel": "Intel",
 "Dell": "Dell",
 "LG": "LG Electronics",
 "Motorola": "Motorola Mobility",
 "Xiaomi": "Xiaomi",
 "Asics": "Asics",
 "Fila": "Fila (company)",
 "Mizuno": "Mizuno",
 "Lacoste": "Lacoste",
 "Calvin Klein": "Calvin Klein (fashion house)",
 "Prada": "Prada",
 "Versace": "Versace",
 "Dior": "Dior",
 "Supreme": "Supreme (brand)",
 "H&M": "H&M",
 "IKEA": "IKEA",
 "Visa": "Visa Inc.",
 "Mastercard": "Mastercard",
 "Shell": "Shell plc",
 "BMW": "BMW",
 "Mercedes-Benz": "Mercedes-Benz",
 "Honda": "Honda",
 "Yamaha": "Yamaha Motor Company",
 "Harley-Davidson": "Harley-Davidson",
 "Porsche": "Porsche",
 "Tesla": "Tesla, Inc.",
 "E.T.": "E.T. the Extra-Terrestrial",
 "Tubarão": "Jaws (film)",
 "Rocky": "Rocky",
 "O Exterminador do Futuro": "The Terminator",
 "Indiana Jones": "Indiana Jones",
 "Piratas do Caribe": "Pirates of the Caribbean (film series)",
 "Velozes e Furiosos": "Fast & Furious",
 "Missão Impossível": "Mission: Impossible (film series)",
 "Kung Fu Panda": "Kung Fu Panda",
 "Carros": "Cars (film)",
 "Up": "Up (2009 film)",
 "Moana": "Moana (2016 film)",
 "Encanto": "Encanto",
 "Minions": "Minions (film)",
 "Meu Malvado Favorito": "Despicable Me",
 "Madagascar": "Madagascar (2005 film)",
 "A Era do Gelo": "Ice Age (2002 film)",
 "Os Incríveis": "The Incredibles",
 "Aladdin": "Aladdin (1992 Disney film)",
 "Pantera Negra": "Black Panther (film)",
 "Homem de Ferro": "Iron Man (2008 film)",
 "Deadpool": "Deadpool (film)",
 "Mad Max": "Mad Max",
 "Alien": "Alien (film)",
 "It: A Coisa": "It (2017 film)",
 "Invocação do Mal": "The Conjuring",
 "Todo Mundo Odeia o Chris": "Everybody Hates Chris",
 "Dragon Ball": "Dragon Ball",
 "Naruto": "Naruto",
 "One Piece": "One Piece",
 "Pokémon": "Pokémon",
 "Bob Esponja": "SpongeBob SquarePants",
 "Scooby-Doo": "Scooby-Doo",
 "Hora de Aventura": "Adventure Time",
 "Sítio do Picapau Amarelo": "Sítio do Picapau Amarelo",
 "Turma da Mônica": "Monica and Friends",
 "A Grande Família": "A Grande Família",
 "Chapolin": "El Chapulín Colorado",
 "Pica-Pau": "Woody Woodpecker",
 "Tom e Jerry": "Tom and Jerry",
 "Lince": "Eurasian lynx",
 "Leopardo": "Leopard",
 "Guepardo": "Cheetah",
 "Hiena": "Spotted hyena",
 "Suricato": "Meerkat",
 "Lontra": "Otter",
 "Castor": "Beaver",
 "Morcego": "Bat",
 "Ouriço": "Hedgehog",
 "Porco-espinho": "Porcupine",
 "Pavão": "Indian peafowl",
 "Avestruz": "Common ostrich",
 "Pelicano": "Pelican",
 "Beija-flor": "Hummingbird",
 "Cisne": "Mute swan",
 "Pato": "Mallard",
 "Galinha": "Chicken",
 "Vaca": "Cattle",
 "Porco": "Pig",
 "Ovelha": "Sheep",
 "Cabra": "Goat",
 "Burro": "Donkey",
 "Alce": "Moose",
 "Bisão": "American bison",
 "Morsa": "Walrus",
 "Foca": "Harbor seal",
 "Orca": "Orca",
 "Água-viva": "Jellyfish",
 "Cavalo-marinho": "Seahorse",
 "Estrela-do-mar": "Starfish",
 "Lula": "Squid",
 "Caranguejo": "Crab",
 "Abelha": "Western honey bee",
 "Formiga": "Ant",
 "Joaninha": "Coccinellidae",
 "Escorpião": "Scorpion",
 "Tarântula": "Tarantula",
 "Sapo": "Common toad",
 "Iguana": "Green iguana",
 "Dragão-de-komodo": "Komodo dragon",
 "Gavião-real": "Harpy eagle",
 "Ema": "Greater rhea",
 "Quati": "South American coati",
 "Anta": "South American tapir"
})

# Segunda tentativa quando a pagina principal nao tem foto livre.
ALTERNATIVOS = {
    'Xavi': 'Xavi Hernández', 'Luis Suárez': 'Luis Suárez (footballer, born 1987)', 'Pastel': 'Pastel (Brazilian food)',
    'Macarrão à bolonhesa': 'Bolognese sauce', 'Pudim': 'Crème caramel', 'Suco de maracujá': 'Passion fruit',
    'Aperol Spritz': 'Aperol', 'Borboleta-azul': 'Morpho menelaus', 'Escondidinho': 'Cassava',
    'Heineken': 'Heineken Pilsener', 'PlayStation': 'PlayStation (console)', 'Netflix': 'Netflix, Inc.',
    'Lacta': 'Laka (chocolate)',
}

# Imagens que nao representam bem o item (predios de sede, capturas de tela): usam o icone.
EXCLUIR = {"aplicativos": ["Airbnb", "AliExpress", "Amazon", "Booking", "Google Meet", "Instagram", "Mercado Livre", "Netflix", "Prime Video", "Reddit", "Shopee", "Spotify", "Uber", "YouTube", "Zoom"], "marcas": ["Amazon", "Google", "Mercado Livre", "Microsoft", "Nestlé", "Netflix", "Nike", "Nintendo", "Petrobras", "Samsung", "Sony", "Spotify", "Starbucks", "Toyota", "Ferrari", "Puma", "Gucci"]}

LICENCAS_LIVRES = re.compile(r'(CC0|CC BY|CC-BY|Public domain|PD|GFDL|Attribution|No restrictions|FAL)', re.I)


def slug(texto):
    t = unicodedata.normalize('NFKD', texto).encode('ascii', 'ignore').decode()
    return re.sub(r'[^a-z0-9]+', '_', t.lower()).strip('_')


def _baixar(url, tentativas=8):
    """GET com espera progressiva; respeita o Retry-After quando o servidor pede calma (429)."""
    erro = None
    for i in range(tentativas):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA})
            with urllib.request.urlopen(req, timeout=40) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            erro = e
            espera = int(e.headers.get('Retry-After') or 0) or 5 * (i + 1)
            time.sleep(min(espera, 60))
        except Exception as e:  # noqa: BLE001
            erro = e
            time.sleep(3 * (i + 1))
    raise erro


def get_json(url):
    return json.loads(_baixar(url))


def get_bytes(url):
    return _baixar(url)


def itens_dos_temas():
    s = open(os.path.join(RAIZ, 'lib', 'data', 'themes_data.dart'), encoding='utf-8').read()
    temas = {}
    for m in re.finditer(r"id: '(\w+)'.*?itens: \[(.*?)\]", s, re.S):
        brutos = re.findall(r"'((?:[^'\\]|\\.)*)'|\"([^\"]*)\"", m.group(2))
        temas[m.group(1)] = [(a or b).replace("\\'", "'") for a, b in brutos]
    return temas


def imagem_da_pagina(titulos):
    """Retorna {titulo_pedido: nome_do_arquivo} usando a imagem principal livre."""
    url = ('https://en.wikipedia.org/w/api.php?action=query&format=json&redirects=1&prop=pageimages'
           '&piprop=name&pilicense=free&titles=' + urllib.parse.quote('|'.join(titulos)))
    d = get_json(url)['query']
    normal = {n['from']: n['to'] for n in d.get('normalized', [])}
    redir = {n['from']: n['to'] for n in d.get('redirects', [])}
    por_titulo = {p['title']: p.get('pageimage') for p in d['pages'].values()}
    res = {}
    for t in titulos:
        final = redir.get(normal.get(t, t), normal.get(t, t))
        res[t] = por_titulo.get(final)
    return res


def metadados(arquivos):
    url = ('https://en.wikipedia.org/w/api.php?action=query&format=json&prop=imageinfo'
           '&iiprop=url|extmetadata|mime&iiurlwidth=%d&titles=' % TAM
           + urllib.parse.quote('|'.join('File:' + a for a in arquivos)))
    d = get_json(url)['query']
    normal = {n['to']: n['from'] for n in d.get('normalized', [])}
    res = {}
    for p in d['pages'].values():
        if 'imageinfo' not in p:
            continue
        ii = p['imageinfo'][0]
        meta = ii.get('extmetadata', {})
        nome = normal.get(p['title'], p['title'])[5:]
        autor = re.sub('<[^>]+>', '', meta.get('Artist', {}).get('value', 'Desconhecido')).strip()
        res[nome.replace(' ', '_')] = {
            'thumb': (ii.get('thumburl') or '').split('?')[0].replace('thumb.wikimedia.org', 'upload.wikimedia.org') or None,
            'mime': ii.get('mime'),
            'licenca': meta.get('LicenseShortName', {}).get('value', ''),
            'autor': autor[:120] or 'Desconhecido',
            'pagina': ii.get('descriptionurl'),
        }
    return res


def processar(conteudo, logo=False):
    im = Image.open(io.BytesIO(conteudo))
    im = ImageOps.exif_transpose(im)
    if im.mode in ('RGBA', 'LA', 'P'):
        im = im.convert('RGBA')
        fundo = Image.new('RGBA', im.size, (255, 255, 255, 255))
        fundo.alpha_composite(im)
        im = fundo
    im = im.convert('RGB')
    if logo:
        # Logotipos (desenhos vetoriais/PNG) sao encaixados inteiros, com margem branca.
        margem = int(TAM * 0.12)
        im.thumbnail((TAM - 2 * margem, TAM - 2 * margem), Image.LANCZOS)
        quadro = Image.new('RGB', (TAM, TAM), (255, 255, 255))
        quadro.paste(im, ((TAM - im.width) // 2, (TAM - im.height) // 2))
        return quadro
    # Fotos sao cortadas em quadrado, priorizando a parte de cima (rostos).
    return ImageOps.fit(im, (TAM, TAM), Image.LANCZOS, centering=(0.5, 0.35))


def main():
    temas = itens_dos_temas()
    creditos = []
    mapa = {}
    for tema, itens in temas.items():
        os.makedirs(os.path.join(SAIDA, tema), exist_ok=True)
        titulos = [TITULOS.get(i, i) for i in itens]
        paginas = {}
        for k in range(0, len(titulos), 20):
            paginas.update(imagem_da_pagina(titulos[k:k + 20]))
            time.sleep(0.5)
        # Itens sem foto: tenta o titulo alternativo.
        faltando = [(i, t) for i, t in zip(itens, titulos) if not paginas.get(t) and i in ALTERNATIVOS]
        if faltando:
            alt = imagem_da_pagina([ALTERNATIVOS[i] for i, _ in faltando])
            for i, t in faltando:
                paginas[t] = alt.get(ALTERNATIVOS[i])
        arquivos = sorted({a for a in paginas.values() if a})
        metas = {}
        for k in range(0, len(arquivos), 20):
            metas.update(metadados(arquivos[k:k + 20]))
            time.sleep(0.5)
        for item, titulo in zip(itens, titulos):
            if item in EXCLUIR.get(tema, []):
                continue
            arq = paginas.get(titulo)
            m = metas.get(arq.replace(' ', '_')) if arq else None
            if not m or not m['thumb'] or not LICENCAS_LIVRES.search(m['licenca'] or ''):
                print('  sem foto livre:', tema, item, '|', arq, '|', m and m['licenca'])
                continue
            destino = os.path.join(tema, slug(item) + '.jpg')
            caminho = os.path.join(SAIDA, destino)
            logo = (m['mime'] or '') in ('image/svg+xml', 'image/png', 'image/gif')
            # REFAZER_LOGOS=1 baixa de novo os logotipos (para encaixar sem cortar).
            if logo and os.environ.get('REFAZER_LOGOS') == '1' and os.path.exists(caminho):
                os.remove(caminho)
            if not os.path.exists(caminho):
                try:
                    processar(get_bytes(m['thumb']), logo).save(caminho, quality=82, optimize=True)
                except Exception as e:  # noqa: BLE001
                    print('  falha ao baixar:', item, e)
                    continue
                time.sleep(1.2)
            mapa[f'{tema}|{item}'] = f'assets/fotos/{destino}'
            creditos.append({'tema': tema, 'item': item, 'autor': m['autor'], 'licenca': m['licenca'],
                             'fonte': m['pagina']})
        print(tema, ':', sum(1 for k in mapa if k.startswith(tema + '|')), 'de', len(itens))
    json.dump(creditos, open(os.path.join(SAIDA, 'creditos.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    with open(os.path.join(RAIZ, 'lib', 'data', 'fotos_data.dart'), 'w', encoding='utf-8') as f:
        f.write('// Gerado por tool/baixar_fotos.py. Nao edite a mao.\n')
        f.write('// Mapa "tema|item" -> foto embutida no app (licencas livres; ver creditos.json).\n\n')
        f.write('const fotosItens = <String, String>{\n')
        for k, v in sorted(mapa.items()):
            f.write('  %s: %s,\n' % (json.dumps(k, ensure_ascii=False), json.dumps(v)))
        f.write('};\n')
    print('total:', len(mapa))


if __name__ == '__main__':
    sys.exit(main())

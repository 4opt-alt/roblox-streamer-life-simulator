import os
import math
import glob
import shutil

def create_rbxlx(auto_push=True):
    base_dir = os.path.dirname(os.path.abspath(__file__))
    src_dir = os.path.join(base_dir, "src")
    
    # Read source files
    # ПРИМІТКА (start-fresh clean-up): Illia попросив прибрати всі механіки/меню
    # (стрім-симуляцію, магазини, лідерборд, robux-стор, керування гіроскутером)
    # і лишити тільки саму фізичну мапу. Тому тут читається і запікається в
    # StreamerGame.rbxlx ЛИШЕ EnvironmentConfig/EnvironmentManager (цикл дня-ночі
    # — це властивість самого світу, а не ігрова механіка/меню). Усі інші
    # старі .luau-файли з src/Client, src/Server, src/Shared (стрім-симуляція,
    # магазини, старий лідерборд тощо) досі НЕ читаються — репозиторій їх
    # фізично не втрачав, build_rbxlx.py просто їх ігнорує.
    #
    # НОВЕ (телефон + ClipZap-економія): перша механіка нової гри "з нуля" —
    # гравець прокидається на звалці без копійки і знімає відео в ClipZap
    # (вигаданий аналог TikTok), щоб заробляти підписників і гроші.
    with open(os.path.join(src_dir, "Shared", "EnvironmentConfig.luau"), "r", encoding="utf-8") as f:
        environment_config_src = f.read()
    with open(os.path.join(src_dir, "Server", "EnvironmentManager.server.luau"), "r", encoding="utf-8") as f:
        environment_manager_src = f.read()
    with open(os.path.join(src_dir, "Shared", "PhoneConfig.luau"), "r", encoding="utf-8") as f:
        phone_config_src = f.read()
    with open(os.path.join(src_dir, "Server", "CreatorEconomyManager.server.luau"), "r", encoding="utf-8") as f:
        creator_economy_manager_src = f.read()
    with open(os.path.join(src_dir, "Client", "PhoneController.client.luau"), "r", encoding="utf-8") as f:
        phone_controller_src = f.read()

    part_counter = [2000]
    def make_part(name, size, pos, rot=(0,0,0), color="4281545523", material=256, anchored=True, can_collide=True, transparency=0, light=None, is_seat=False, shape=None, children_xml=""):
        part_counter[0] += 1
        ref = f"RBX_Part_{part_counter[0]}"
        cls = "VehicleSeat" if is_seat == "vehicle" else ("Seat" if is_seat == True else "Part")
        
        rx, ry, rz = rot
        cx, sx = math.cos(math.radians(rx)), math.sin(math.radians(rx))
        cy, sy = math.cos(math.radians(ry)), math.sin(math.radians(ry))
        cz, sz = math.cos(math.radians(rz)), math.sin(math.radians(rz))
        
        r00 = cy * cz
        r01 = -cy * sz
        r02 = sy
        r10 = sx * sy * cz + cx * sz
        r11 = -sx * sy * sz + cx * cz
        r12 = -sx * cy
        r20 = -cx * sy * cz + sx * sz
        r21 = cx * sy * sz + sx * cz
        r22 = cx * cy

        light_xml = ""
        if light:
            l_type, l_color, l_bright, l_range = light
            light_xml = f'''
				<Item class="{l_type}" referent="{ref}_Light">
					<Properties>
						<Color3 name="Color"><R>{l_color[0]}</R><G>{l_color[1]}</G><B>{l_color[2]}</B></Color3>
						<float name="Brightness">{l_bright}</float>
						<float name="Range">{l_range}</float>
						<bool name="Shadows">true</bool>
					</Properties>
				</Item>'''

        shape_xml = f'<token name="shape">{shape}</token>' if shape else ''

        return f'''
		<Item class="{cls}" referent="{ref}">
			<Properties>
				<string name="Name">{name}</string>
				<bool name="Anchored">{str(anchored).lower()}</bool>
				<bool name="CanCollide">{str(can_collide).lower()}</bool>
				<float name="Transparency">{transparency}</float>
				<Vector3 name="size">
					<X>{size[0]}</X><Y>{size[1]}</Y><Z>{size[2]}</Z>
				</Vector3>
				<CoordinateFrame name="CFrame">
					<X>{pos[0]}</X><Y>{pos[1]}</Y><Z>{pos[2]}</Z>
					<R00>{r00:.4f}</R00><R01>{r01:.4f}</R01><R02>{r02:.4f}</R02>
					<R10>{r10:.4f}</R10><R11>{r11:.4f}</R11><R12>{r12:.4f}</R12>
					<R20>{r20:.4f}</R20><R21>{r21:.4f}</R21><R22>{r22:.4f}</R22>
				</CoordinateFrame>
				<Color3uint8 name="Color3uint8">{color}</Color3uint8>
				<token name="Material">{material}</token>
				{shape_xml}
			</Properties>{light_xml}{children_xml}
		</Item>'''

    # Materials:
    # 256: SmoothPlastic, 272: WoodPlanks, 288: Neon, 304: Glass, 800: Metal/DiamondPlate, 816: Fabric, 1280: Grass, 1296: Slate/Rock
    GRASS_GREEN = 4283863870
    ROAD_ASPHALT = 4281348144   # rgb(32, 33, 38)
    ROAD_MARK_YELLOW = 4294956800
    ROAD_MARK_WHITE = 4294967295
    SIDEWALK_GREY = 4287335307  # rgb(125, 130, 140)
    DARK_WALL = 4281677362
    WOOD_FLOOR = 4284105021
    CEILING_COLOR = 4282335025
    DESK_TOP = 4280295454
    DESK_LEGS = 4279900698
    RGB_CYAN = 4283549695
    RGB_PURPLE = 4290781439
    SCREEN_COLOR = 4280826955
    CHAIR_RED = 4293994546
    CHAIR_BLACK = 4280295454
    RUG_COLOR = 4283852150
    GOLD_COLOR = 4294956800
    TECH_PLAZA = 4282335025
    HOVER_NAVY_DARK = 4279376444   # rgb(18, 26, 60) - деко-корпус "галактика"
    HOVER_GRIP_BLACK = 4279374356  # rgb(18, 18, 20) - чорна протиковзка накладка
    HOVER_WHEEL_BLACK = 4278979598 # rgb(12, 12, 14) - колеса
    HOVER_LED_BLUE = 4282166015    # rgb(60, 170, 255) - синя LED-підсвітка

    # Кольори для розширення міста (басейн, зоопарк, колізей, особняки)
    POOL_WATER = 4282430694        # rgb(64,180,230)
    POOL_TILE = 4293651425         # rgb(235,235,225)
    POOL_TILE_BLUE = 4282158270    # rgb(60,140,190)
    ZOO_GRASS = 4282810940         # rgb(70,130,60)
    ZOO_FENCE = 4285419570         # rgb(110,80,50)
    ZOO_ROCK = 4286082660          # rgb(120,110,100)
    MANSION_WHITE = 4294308584     # rgb(245,242,232)
    MANSION_ROOF_DARK = 4280821808 # rgb(40,40,48)
    MANSION_GATE = 4279505944      # rgb(20,20,24)
    COLOSSEUM_STONE = 4291080332   # rgb(196,176,140)
    COLOSSEUM_SAND = 4292260480    # rgb(214,178,128)
    COLOSSEUM_STONE_LIGHT = 4292265120  # rgb(214,196,160) — освітлені пілони (передній план)
    COLOSSEUM_STONE_MID = 4291343504    # rgb(200,180,144) — 2й ярус
    ARCH_SHADOW = 4280031252            # rgb(28,24,20) — темна заглиблена арка
    COLOSSEUM_FLOODLIGHT = 4294962110   # rgb(255,235,190) — тепле підсвічування прожекторами
    SILVER_COLOR = 4290692040      # rgb(190,195,200)
    BRONZE_COLOR = 4288043570      # rgb(150,90,50)
    LAMP_WARM = 4294959540         # rgb(255,225,180)
    GLASS_BLUE = 4287419135        # rgb(140,210,255)

    # Кольори для звалки (нова спавн-зона замість будинку стрімера)
    JUNK_GROUND = 4283977278        # rgb(88,78,62) - земля/гравій
    JUNK_RUST = 4286201372          # rgb(122,62,28) - іржавий метал
    JUNK_RUST_DARK = 4283312148     # rgb(78,40,20) - темна іржа
    JUNK_METAL_GREY = 4284244060    # rgb(92,96,92) - тьмяний метал
    JUNK_METAL_DARK = 4281611828    # rgb(52,54,52) - темний метал
    JUNK_TIRE_BLACK = 4279637528    # rgb(22,22,24) - шини
    JUNK_FENCE = 4282925626         # rgb(72,66,58) - паркан
    JUNK_TRASH = 4283187758         # rgb(76,66,46) - купи сміття
    JUNK_CONTAINER = 4287514134     # rgb(142,70,22) - контейнер
    JUNK_CONTAINER_DARK = 4284231184 # rgb(92,46,16) - тінь контейнера
    JUNK_LIGHT_WARM = 4294953090    # rgb(255,200,130) - тепле світло ліхтаря

    badge_counter = [3000]
    def label_children(text, bg_color=(0.08, 0.12, 0.18), stroke_color=(0.2, 0.8, 1.0), width=220, height=46, offset_y=3.5):
        badge_counter[0] += 1
        bid = f"RBX_Badge_{badge_counter[0]}"
        return f'''
				<Item class="BillboardGui" referent="{bid}">
					<Properties>
						<string name="Name">Badge</string>
						<Vector3 name="StudsOffset"><X>0</X><Y>{offset_y}</Y><Z>0</Z></Vector3>
						<UDim2 name="Size"><XS>0</XS><XO>{width}</XO><YS>0</YS><YO>{height}</YO></UDim2>
						<bool name="AlwaysOnTop">true</bool>
						<float name="MaxDistance">100</float>
						<float name="LightInfluence">0</float>
					</Properties>
					<Item class="Frame" referent="{bid}_F">
						<Properties>
							<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO></UDim2>
							<Color3 name="BackgroundColor3"><R>{bg_color[0]}</R><G>{bg_color[1]}</G><B>{bg_color[2]}</B></Color3>
							<float name="BackgroundTransparency">0.2</float>
						</Properties>
						<Item class="UICorner" referent="{bid}_C">
							<Properties><UDim name="CornerRadius"><S>0</S><O>10</O></UDim></Properties>
						</Item>
						<Item class="UIStroke" referent="{bid}_S">
							<Properties>
								<Color3 name="Color"><R>{stroke_color[0]}</R><G>{stroke_color[1]}</G><B>{stroke_color[2]}</B></Color3>
								<float name="Thickness">2</float>
							</Properties>
						</Item>
						<Item class="TextLabel" referent="{bid}_L">
							<Properties>
								<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO></UDim2>
								<float name="BackgroundTransparency">1</float>
								<string name="Text">{text}</string>
								<Color3 name="TextColor3"><R>1</R><G>1</G><B>1</B></Color3>
								<token name="Font">17</token>
								<float name="TextSize">15</float>
							</Properties>
						</Item>
					</Item>
				</Item>'''

    prompt_counter = [3000]
    def shop_children(prompt_name, object_text, action_text, badge_text, bg_color=(0.08, 0.12, 0.18), stroke_color=(0.2, 0.8, 1.0)):
        # Раніше тут ще додавався ProximityPrompt ("Натисни E") — прибрано разом
        # з усіма магазинними/стрімерськими механіками: без ShopManager/ShopGui
        # натискання E все одно нічого б не робило. Лишилась тільки вивіска
        # (BillboardGui) — будівля виглядає як звичайна споруда на мапі.
        return label_children(badge_text, bg_color, stroke_color)

    city_parts = []

    # =========================================================================
    # 1. GROUND
    # =========================================================================
    # Illia попросив прибрати з мапи геть усе, крім Колізею і дороги до нього —
    # тому стара пряма вулиця, ліхтарі, дерева та декоративний скайлайн
    # (CityBuilding1-3) прибрані. Лишається лише базова земля під ногами.
    city_parts.append(make_part("CityGround", (1024, 4, 1024), (0, -2, 80), color=GRASS_GREEN, material=1280))

    # =========================================================================
    # 2. THE SCRAPYARD — нова спавн-зона замість будинку стрімера. Гравці
    #    з'являються тут і йдуть прямою дорогою на північ до Колізею — це
    #    єдині дві речі, які Illia попросив лишити на мапі.
    # =========================================================================
    JUNK_CX, JUNK_CZ = 0, -30
    JUNK_HALF_W, JUNK_HALF_D = 45, 40   # X: -45..45, Z: -70..10
    JUNK_GATE_HALF = 16                 # ширина проходу в паркані (трохи ширша за дорогу)

    city_parts.append(make_part("JunkyardGround", (JUNK_HALF_W * 2, 0.6, JUNK_HALF_D * 2), (JUNK_CX, 0.3, JUNK_CZ), color=JUNK_GROUND, material=800))

    # Паркан по периметру — суцільний з трьох сторін, з проїздом на північ (до дороги)
    city_parts.append(make_part("JunkFenceS", (JUNK_HALF_W * 2, 10, 1), (JUNK_CX, 5, JUNK_CZ - JUNK_HALF_D), color=JUNK_FENCE, material=272))
    city_parts.append(make_part("JunkFenceE", (1, 10, JUNK_HALF_D * 2), (JUNK_CX + JUNK_HALF_W, 5, JUNK_CZ), color=JUNK_FENCE, material=272))
    city_parts.append(make_part("JunkFenceW", (1, 10, JUNK_HALF_D * 2), (JUNK_CX - JUNK_HALF_W, 5, JUNK_CZ), color=JUNK_FENCE, material=272))
    north_seg_w = JUNK_HALF_W - JUNK_GATE_HALF
    city_parts.append(make_part("JunkFenceNL", (north_seg_w, 10, 1), (JUNK_CX - JUNK_HALF_W + north_seg_w / 2, 5, JUNK_CZ + JUNK_HALF_D), color=JUNK_FENCE, material=272))
    city_parts.append(make_part("JunkFenceNR", (north_seg_w, 10, 1), (JUNK_CX + JUNK_HALF_W - north_seg_w / 2, 5, JUNK_CZ + JUNK_HALF_D), color=JUNK_FENCE, material=272))
    city_parts.append(make_part("JunkGatePostL", (1.2, 11, 1.2), (JUNK_CX - JUNK_GATE_HALF, 5.5, JUNK_CZ + JUNK_HALF_D), color=JUNK_RUST_DARK, material=272))
    city_parts.append(make_part("JunkGatePostR", (1.2, 11, 1.2), (JUNK_CX + JUNK_GATE_HALF, 5.5, JUNK_CZ + JUNK_HALF_D), color=JUNK_RUST_DARK, material=272))
    gate_sign_children = label_children("🗑️ THE SCRAPYARD — Спавн", bg_color=(0.10, 0.08, 0.05), stroke_color=(0.85, 0.45, 0.2), width=260, height=48)
    city_parts.append(make_part("JunkGateSign", (JUNK_GATE_HALF * 2 + 2, 2, 0.6), (JUNK_CX, 11.2, JUNK_CZ + JUNK_HALF_D), color=JUNK_METAL_DARK, material=256, children_xml=gate_sign_children))

    # Розкидані по двору купи брухту, розбиті машини, шини, сміття — суто декор
    def junk_pile(name, cx, cz, count=4):
        parts = []
        for i in range(count):
            w = 2.5 + (i % 3) * 1.1
            h = 1.0 + (i % 2) * 0.8
            d = 2.0 + ((i + 1) % 3) * 0.9
            px = cx + (i - count / 2) * 0.6
            pz = cz + ((i * 37) % 5 - 2) * 0.5
            py = 0.5 + i * 0.55
            ry = (i * 53) % 180
            col = JUNK_METAL_GREY if i % 2 == 0 else JUNK_RUST
            parts.append(make_part(f"{name}_{i}", (w, h, d), (px, py, pz), rot=(0, ry, 0), color=col, material=256))
        return parts

    for pname, px, pz in [("ScrapPile1", -30, -12), ("ScrapPile2", 28, -50), ("ScrapPile3", -32, -55), ("ScrapPile4", 20, -8)]:
        city_parts.extend(junk_pile(pname, px, pz))

    # Розбиті машини (прості коробки-корпуси під кутом, ніби покинуті)
    city_parts.append(make_part("CarWreck1Body", (7.0, 2.6, 15.0), (-24, 1.4, -48), rot=(0, 12, 0), color=JUNK_RUST, material=256))
    city_parts.append(make_part("CarWreck1Glass", (6.4, 1.0, 5.0), (-24, 2.9, -48), rot=(0, 12, 0), color=JUNK_METAL_DARK, material=304, transparency=0.3))
    city_parts.append(make_part("CarWreck2Body", (6.2, 2.3, 13.0), (26, 1.2, -18), rot=(0, -18, 0), color=JUNK_RUST_DARK, material=256))
    city_parts.append(make_part("CarWreck2Glass", (5.6, 0.9, 4.4), (26, 2.5, -18), rot=(0, -18, 0), color=JUNK_METAL_DARK, material=304, transparency=0.3))

    # Стос шин (пласкі циліндри, складені один на одного)
    def tire_stack(name, cx, cz, count=4):
        parts = []
        for i in range(count):
            parts.append(make_part(f"{name}_{i}", (2.6, 0.8, 2.6), (cx, 0.4 + i * 0.85, cz), rot=(0, 0, 90), shape=2, color=JUNK_TIRE_BLACK, material=816))
        return parts

    city_parts.extend(tire_stack("TireStack1", -12, -58, 5))
    city_parts.extend(tire_stack("TireStack2", 10, -35, 3))

    # Купи сміття (сплющені кулі)
    city_parts.append(make_part("TrashMound1", (4.5, 1.6, 4.0), (0, 0.8, -60), shape=1, color=JUNK_TRASH, material=816))
    city_parts.append(make_part("TrashMound2", (3.5, 1.3, 3.2), (-6, 0.65, -22), shape=1, color=JUNK_TRASH, material=816))

    # Іржавий контейнер уздовж південного паркану
    city_parts.append(make_part("JunkContainer", (5.5, 8.0, 22.0), (36, 4.0, -50), color=JUNK_CONTAINER, material=256))
    city_parts.append(make_part("JunkContainerStripe", (5.7, 0.6, 22.2), (36, 6.0, -50), color=JUNK_CONTAINER_DARK, material=256))
    city_parts.append(make_part("JunkContainerDoor", (0.3, 7.4, 6.0), (33.1, 3.9, -50), color=JUNK_CONTAINER_DARK, material=256))

    # Кран-щогла з ліхтарем — освітлює двір і дає силует "звалки" на горизонті
    city_parts.append(make_part("JunkCranePole", (1.0, 22, 1.0), (-38, 11, -55), color=JUNK_METAL_DARK, material=256))
    city_parts.append(make_part("JunkCraneArm", (1.0, 1.0, 14), (-38, 21.5, -48), color=JUNK_METAL_DARK, material=256))
    city_parts.append(make_part("JunkCraneHook", (0.3, 3, 0.3), (-38, 19, -42), color=JUNK_METAL_DARK, material=256))
    city_parts.append(make_part("JunkCraneLight", (1.4, 0.5, 1.4), (-38, 20.8, -42), color=JUNK_LIGHT_WARM, material=288,
                                light=("SpotLight", (1.0, 0.8, 0.55), 5.0, 60)))

    # Пара тьмяних прожекторів на парканах для атмосфери вночі
    for lx, lz in [(-40, 5), (40, 5)]:
        city_parts.append(make_part(f"JunkFenceLightPole_{lx}", (0.5, 9, 0.5), (lx, 4.5, lz), color=JUNK_METAL_DARK, material=800))
        city_parts.append(make_part(f"JunkFenceLight_{lx}", (1.0, 0.4, 1.0), (lx, 9.2, lz), color=JUNK_LIGHT_WARM, material=288,
                                    light=("PointLight", (1.0, 0.8, 0.5), 2.0, 24)))

    # =========================================================================
    # 2b. ROAD TO THE COLOSSEUM — пряма дорога від воріт звалки (Z=10) до
    #     південного входу в Колізей (Z=475). Це єдина дорога на мапі.
    # =========================================================================
    ROAD_W = 28
    road_z0, road_z1 = JUNK_CZ + JUNK_HALF_D, 475
    road_len = road_z1 - road_z0
    road_cz = (road_z0 + road_z1) / 2

    city_parts.append(make_part("RoadToColosseumAsphalt", (ROAD_W, 0.4, road_len), (0, 0.2, road_cz), color=ROAD_ASPHALT, material=256))
    city_parts.append(make_part("RoadEdgeL", (0.5, 0.42, road_len - 2), (-ROAD_W / 2, 0.22, road_cz), color=ROAD_MARK_WHITE, material=256))
    city_parts.append(make_part("RoadEdgeR", (0.5, 0.42, road_len - 2), (ROAD_W / 2, 0.22, road_cz), color=ROAD_MARK_WHITE, material=256))
    city_parts.append(make_part("SidewalkLeft", (10, 0.8, road_len), (-ROAD_W / 2 - 5, 0.4, road_cz), color=SIDEWALK_GREY, material=800))
    city_parts.append(make_part("SidewalkRight", (10, 0.8, road_len), (ROAD_W / 2 + 5, 0.4, road_cz), color=SIDEWALK_GREY, material=800))

    zl = int(road_z0) + 12
    while zl < road_z1 - 12:
        city_parts.append(make_part(f"RoadCenterLine_{zl}", (0.5, 0.42, 10), (0, 0.22, zl), color=ROAD_MARK_YELLOW, material=288))
        zl += 16

    for z_light in range(int(road_z0) + 50, int(road_z1) - 30, 80):
        city_parts.append(make_part(f"StreetPoleL_{z_light}", (0.6, 14, 0.6), (-23, 7, z_light), color=DESK_LEGS, material=800))
        city_parts.append(make_part(f"StreetArmL_{z_light}", (5, 0.5, 0.5), (-20.5, 13.8, z_light), color=DESK_LEGS, material=800))
        city_parts.append(make_part(f"StreetLampL_{z_light}", (1.2, 0.4, 1.2), (-18.2, 13.6, z_light), color=4294967295, material=288,
                                    light=("PointLight", (1.0, 0.95, 0.8), 2.2, 28)))
        city_parts.append(make_part(f"StreetPoleR_{z_light}", (0.6, 14, 0.6), (23, 7, z_light), color=DESK_LEGS, material=800))
        city_parts.append(make_part(f"StreetArmR_{z_light}", (5, 0.5, 0.5), (20.5, 13.8, z_light), color=DESK_LEGS, material=800))
        city_parts.append(make_part(f"StreetLampR_{z_light}", (1.2, 0.4, 1.2), (18.2, 13.6, z_light), color=4294967295, material=288,
                                    light=("PointLight", (1.0, 0.95, 0.8), 2.2, 28)))

    # 10. TOP STREAMERS COLOSSEUM — справжня арена з ярусами арок (як у Римі),
    #     не просто рівна стіна. X=0, Z=560, кінець North Avenue.
    # =========================================================================
    COL_CX, COL_CZ, COL_R = 0, 530, 55
    SEGMENTS = 32
    GATE_SEGMENTS = {14, 15, 16, 17, 18}  # широкий розрив кільця = вхід з боку North Avenue (південь)
    seg_deg = 360 / SEGMENTS
    seg_width = (2 * math.pi * COL_R / SEGMENTS) * 1.06
    PIER_W = 2.6       # ширина світлого пілона (стовпа) між арками
    RECESS = 1.3        # на скільки заглиблена темна арка відносно пілонів
    ARCH_GAP = 0.4

    def colosseum_ring(radius, y_center, height, stone_color, tier_label):
        """Один ярус арени: по колу чергуються світлі пілони і темні заглиблені 'арки'."""
        for i in range(SEGMENTS):
            if i in GATE_SEGMENTS:
                continue
            deg = i * seg_deg
            ang = math.radians(deg)
            s, cco = math.sin(ang), math.cos(ang)
            tx, tz = math.cos(ang), -math.sin(ang)  # тангенціальний напрямок (вздовж кільця)
            outer_x, outer_z = COL_CX + radius * s, COL_CZ + radius * cco
            inner_x, inner_z = COL_CX + (radius - RECESS) * s, COL_CZ + (radius - RECESS) * cco
            off = (seg_width - PIER_W) / 2
            arch_w = max(1.0, seg_width - 2 * PIER_W - ARCH_GAP)
            city_parts.append(make_part(f"ColPier_{tier_label}_{i}L", (PIER_W, height, 3.0),
                                        (outer_x - tx * off, y_center, outer_z - tz * off),
                                        rot=(0, deg, 0), color=stone_color, material=256))
            city_parts.append(make_part(f"ColPier_{tier_label}_{i}R", (PIER_W, height, 3.0),
                                        (outer_x + tx * off, y_center, outer_z + tz * off),
                                        rot=(0, deg, 0), color=stone_color, material=256))
            city_parts.append(make_part(f"ColArch_{tier_label}_{i}", (arch_w, height * 0.86, 2.0),
                                        (inner_x, y_center, inner_z),
                                        rot=(0, deg, 0), color=ARCH_SHADOW, material=256))
            # маленький підсвічений "замковий камінь" над аркою для акценту
            city_parts.append(make_part(f"ColKeystone_{tier_label}_{i}", (min(1.4, arch_w * 0.3), 1.0, 2.2),
                                        (outer_x, y_center + height * 0.5 - 0.2, outer_z),
                                        rot=(0, deg, 0), color=COLOSSEUM_FLOODLIGHT, material=288))

    # Ярус 1 (нижній, найширший)
    colosseum_ring(COL_R, 5.5, 11, COLOSSEUM_STONE_LIGHT, "T1")
    # Ярус 2 (трохи вужчий і коротший — як справжній Колізей "звужується" догори)
    colosseum_ring(COL_R - 2.5, 15.5, 9, COLOSSEUM_STONE_MID, "T2")
    # Горішній суцільний "аттик"-пояс + ряд стовпчиків на гребені (як риштування на фото-референсі)
    for i in range(SEGMENTS):
        if i in GATE_SEGMENTS:
            continue
        deg = i * seg_deg
        ang = math.radians(deg)
        s, cco = math.sin(ang), math.cos(ang)
        ax, az = COL_CX + (COL_R - 2.5) * s, COL_CZ + (COL_R - 2.5) * cco
        city_parts.append(make_part(f"ColAttic_{i}", (seg_width, 3, 3.4), (ax, 21.5, az), rot=(0, deg, 0), color=COLOSSEUM_STONE, material=256))
        city_parts.append(make_part(f"ColPole_{i}", (0.35, 5, 0.35), (ax, 25.5, az), color=DESK_LEGS, material=800))

    # Кругла піщана арена (циліндр, покладений пласко: rot=(0,0,90) ставить вісь вертикально)
    city_parts.append(make_part("ColosseumFloor", (1.5, COL_R * 2 - 6, COL_R * 2 - 6), (COL_CX, 0.5, COL_CZ), rot=(0, 0, 90), shape=2, color=COLOSSEUM_SAND, material=256))
    city_parts.append(make_part("ColosseumInnerRing", (1.6, COL_R * 1.3, COL_R * 1.3), (COL_CX, 0.55, COL_CZ), rot=(0, 0, 90), shape=2, color=COLOSSEUM_STONE, material=256))

    # Прожектори знизу вгору попід стінами (щоб фасад був виразно освітлений, а не в суцільній тіні)
    for fl_deg in (0, 45, 90, 135, 225, 270, 315):
        fl_ang = math.radians(fl_deg)
        fx = COL_CX + (COL_R - 6) * math.sin(fl_ang)
        fz = COL_CZ + (COL_R - 6) * math.cos(fl_ang)
        city_parts.append(make_part(f"ColFloodlight_{fl_deg}", (1.2, 1.2, 1.2), (fx, 1.0, fz), color=4294967295, material=288,
                                    light=("SpotLight", (1.0, 0.92, 0.75), 4.0, 60)))

    # П'єдестал ТОП-3 стрімерів у центрі арени
    city_parts.append(make_part("PodiumFirst", (7, 4, 7), (COL_CX, 2, COL_CZ), color=GOLD_COLOR, material=800))
    city_parts.append(make_part("PodiumSecond", (6, 2.6, 6), (COL_CX - 9, 1.3, COL_CZ), color=SILVER_COLOR, material=800))
    city_parts.append(make_part("PodiumThird", (6, 2.0, 6), (COL_CX + 9, 1.0, COL_CZ), color=BRONZE_COLOR, material=800))
    podium_sign_children = label_children("🥇 TOP СТРІМЕР СЕРВЕРА", bg_color=(0.2, 0.16, 0.0), stroke_color=(1.0, 0.85, 0.0), width=260, height=50)
    city_parts.append(make_part("PodiumFirstFlag", (0.4, 6, 0.4), (COL_CX, 7, COL_CZ), color=DESK_LEGS, material=800, children_xml=podium_sign_children))

    # Велика вивіска на північній внутрішній стіні арени (навпроти входу)
    colosseum_title_children = label_children("🏛️ COLOSSEUM OF STREAMERS", bg_color=(0.12, 0.09, 0.02), stroke_color=(1.0, 0.85, 0.0), width=320, height=56)
    city_parts.append(make_part("ColosseumSignPanel", (22, 8, 0.6), (COL_CX, 15, COL_CZ + COL_R - 4), color=MANSION_ROOF_DARK, material=256, children_xml=colosseum_title_children))
    city_parts.append(make_part("ColosseumSignNeon", (21.4, 7.4, 0.1), (COL_CX, 15, COL_CZ + COL_R - 3.65), color=GOLD_COLOR, material=288,
                                light=("PointLight", (1.0, 0.85, 0.0), 3.0, 34)))

    # Ворота-арка з боку North Avenue (південний розрив кільця, точно навпроти вулиці)
    gate_z = COL_CZ - COL_R
    city_parts.append(make_part("ColosseumArchL", (4, 24, 4), (-21, 12, gate_z), color=COLOSSEUM_STONE, material=256))
    city_parts.append(make_part("ColosseumArchR", (4, 24, 4), (21, 12, gate_z), color=COLOSSEUM_STONE, material=256))
    arch_sign_children = label_children("🏟️ Colosseum of Streamers", bg_color=(0.12, 0.09, 0.02), stroke_color=(1.0, 0.85, 0.0))
    city_parts.append(make_part("ColosseumArchTop", (48, 4, 4), (0, 25, gate_z), color=COLOSSEUM_STONE, material=256, children_xml=arch_sign_children))
    city_parts.append(make_part("ColosseumArchGlow", (46, 0.3, 0.3), (0, 22.7, gate_z), color=GOLD_COLOR, material=288,
                                light=("PointLight", (1.0, 0.85, 0.0), 2.0, 26)))

    all_parts_xml = "\n".join(city_parts)

    # SpawnLocation тепер на Звалці (JUNK_CX, JUNK_CZ), дивиться на північ (+Z)
    # у бік воріт паркану й дороги до Колізею.
    spawn_xml = '''
		<Item class="SpawnLocation" referent="RBX_Spawn">
			<Properties>
				<string name="Name">SpawnLocation</string>
				<bool name="Anchored">true</bool>
				<bool name="CanCollide">true</bool>
				<float name="Transparency">1</float>
				<Vector3 name="size">
					<X>6</X><Y>0.2</Y><Z>6</Z>
				</Vector3>
				<CoordinateFrame name="CFrame">
					<X>0</X><Y>1.8</Y><Z>-30</Z>
					<R00>-1</R00><R01>0</R01><R02>0</R02>
					<R10>0</R10><R11>1</R11><R12>0</R12>
					<R20>0</R20><R21>0</R21><R22>-1</R22>
				</CoordinateFrame>
				<token name="Neutral">1</token>
				<int name="Duration">0</int>
			</Properties>
		</Item>'''

    rbxlx_content = f'''<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
	<External>null</External>
	<External>nil</External>
	<Item class="Workspace" referent="RBX_Workspace">
		<Properties>
			<bool name="FilteringEnabled">true</bool>
			<string name="Name">Workspace</string>
			<bool name="StreamingEnabled">false</bool>
		</Properties>
		<Item class="Model" referent="RBX_CityWorld">
			<Properties>
				<string name="Name">CityWorld</string>
			</Properties>
			{all_parts_xml}
			{spawn_xml}
		</Item>
		<Item class="Clouds" referent="RBX_Clouds">
			<Properties>
				<string name="Name">Clouds</string>
				<Color3 name="Color">
					<R>1</R><G>1</G><B>1</B>
				</Color3>
				<float name="Cover">0.38</float>
				<float name="Density">0.55</float>
			</Properties>
		</Item>
	</Item>
	<Item class="ReplicatedStorage" referent="RBX_ReplicatedStorage">
		<Properties>
			<string name="Name">ReplicatedStorage</string>
		</Properties>
		<Item class="Folder" referent="RBX_SharedFolder">
			<Properties>
				<string name="Name">Shared</string>
			</Properties>
			<Item class="ModuleScript" referent="RBX_EnvironmentConfig">
				<Properties>
					<string name="Name">EnvironmentConfig</string>
					<ProtectedString name="Source"><![CDATA[{environment_config_src}]]></ProtectedString>
				</Properties>
			</Item>
			<Item class="ModuleScript" referent="RBX_PhoneConfig">
				<Properties>
					<string name="Name">PhoneConfig</string>
					<ProtectedString name="Source"><![CDATA[{phone_config_src}]]></ProtectedString>
				</Properties>
			</Item>
		</Item>
	</Item>
	<Item class="ServerScriptService" referent="RBX_ServerScriptService">
		<Properties>
			<string name="Name">ServerScriptService</string>
		</Properties>
		<Item class="Script" referent="RBX_EnvironmentManager">
			<Properties>
				<string name="Name">EnvironmentManager</string>
				<ProtectedString name="Source"><![CDATA[{environment_manager_src}]]></ProtectedString>
			</Properties>
		</Item>
		<Item class="Script" referent="RBX_CreatorEconomyManager">
			<Properties>
				<string name="Name">CreatorEconomyManager</string>
				<ProtectedString name="Source"><![CDATA[{creator_economy_manager_src}]]></ProtectedString>
			</Properties>
		</Item>
	</Item>
	<Item class="StarterPlayer" referent="RBX_StarterPlayer">
		<Properties>
			<string name="Name">StarterPlayer</string>
		</Properties>
		<Item class="StarterPlayerScripts" referent="RBX_StarterPlayerScripts">
			<Properties>
				<string name="Name">StarterPlayerScripts</string>
			</Properties>
			<Item class="LocalScript" referent="RBX_PhoneController">
				<Properties>
					<string name="Name">PhoneController</string>
					<ProtectedString name="Source"><![CDATA[{phone_controller_src}]]></ProtectedString>
				</Properties>
			</Item>
		</Item>
	</Item>
	<Item class="Lighting" referent="RBX_Lighting">
		<Properties>
			<string name="Name">Lighting</string>
			<Color3 name="Ambient">
				<R>0.549</R><G>0.569</G><B>0.647</B>
			</Color3>
			<Color3 name="OutdoorAmbient">
				<R>0.588</R><G>0.647</G><B>0.765</B>
			</Color3>
			<float name="Brightness">2.6</float>
			<float name="ClockTime">12.0</float>
			<float name="GeographicLatitude">35</float>
		</Properties>
		<Item class="Sky" referent="RBX_Sky">
			<Properties>
				<string name="Name">Sky</string>
			</Properties>
		</Item>
		<Item class="Atmosphere" referent="RBX_Atmosphere">
			<Properties>
				<string name="Name">Atmosphere</string>
				<float name="Density">0.3</float>
				<float name="Offset">0.25</float>
				<Color3 name="Color">
					<R>0.780</R><G>0.780</G><B>0.780</B>
				</Color3>
				<Color3 name="Decay">
					<R>0.439</R><G>0.490</G><B>0.6</B>
				</Color3>
				<float name="Glare">0.2</float>
				<float name="Haze">1.3</float>
			</Properties>
		</Item>
	</Item>
</roblox>'''

    output_path = os.path.join(base_dir, "StreamerGame.rbxlx")
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(rbxlx_content)
    print(f"Generated successfully: {output_path} ({os.path.getsize(output_path)} bytes)")

    # Також копіюємо на Робочий стіл — ЦЕ БУЛО ЗАХАРДКОДЖЕНО НА "lyutu" (чужий Windows-профіль,
    # якого нема ні в Illia (illad), ні, можливо, у друга) — тому щоразу падало з
    # FileNotFoundError і watcher-скрипт тихо ковтав цю помилку (except: pass), а це, схоже,
    # і була причина, чому нові зміни не з'являлись у грі. Тепер шлях обчислюється динамічно
    # для того, хто реально запускає скрипт, і обгорнутий у try/except, щоб навіть якщо
    # Робочого столу немає — основний файл у самій папці проєкту (output_path вище) все одно
    # вже записаний і саме його треба відкривати в Studio.
    try:
        desktop_path = os.path.join(os.path.expanduser("~"), "Desktop", "StreamerGame.rbxlx")
        with open(desktop_path, "w", encoding="utf-8") as f:
            f.write(rbxlx_content)
        print(f"Copied to Desktop: {desktop_path} ({os.path.getsize(desktop_path)} bytes)")
    except Exception as desktop_err:
        print(f"Desktop copy skipped (not critical, project copy above is the real file): {desktop_err}")

    def _find_git_exe():
        # 1) git у PATH (найнадійніше, працює для будь-якого користувача)
        found = shutil.which("git")
        if found:
            return found
        # 2) вбудований git з GitHub Desktop — шлях залежить від імені користувача Windows,
        #    тож шукаємо динамічно (%LOCALAPPDATA%), а не хардкодимо чиєсь конкретне ім'я.
        local_appdata = os.environ.get("LOCALAPPDATA")
        if local_appdata:
            matches = glob.glob(os.path.join(local_appdata, "GitHubDesktop", "app-*", "resources", "app", "git", "cmd", "git.exe"))
            if matches:
                matches.sort(reverse=True)
                return matches[0]
        return None

    # Auto-sync to Git & GitHub
    if auto_push:
        try:
            import subprocess, time
            git_cmd = _find_git_exe()
            if git_cmd and os.path.exists(git_cmd):
                subprocess.run([git_cmd, "add", "-A"], cwd=base_dir, check=False)
                now_str = time.strftime("%Y-%m-%d %H:%M:%S")
                subprocess.run([git_cmd, "commit", "-m", f"Auto-sync build: {now_str}"], cwd=base_dir, check=False)
                rem = subprocess.run([git_cmd, "remote"], cwd=base_dir, capture_output=True, text=True, check=False)
                if rem.stdout.strip():
                    subprocess.run([git_cmd, "push", "origin", "main"], cwd=base_dir, check=False)
                    print("Auto-synced and pushed to GitHub!")
        except Exception as e:
            print(f"Git auto-sync notice: {e}")

if __name__ == "__main__":
    create_rbxlx()


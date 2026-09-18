import os
import math
import glob
import shutil

def create_rbxlx(auto_push=True):
    base_dir = os.path.dirname(os.path.abspath(__file__))
    src_dir = os.path.join(base_dir, "src")
    
    # Read source files
    with open(os.path.join(src_dir, "Shared", "StreamConfig.luau"), "r", encoding="utf-8") as f:
        stream_config_src = f.read()
    with open(os.path.join(src_dir, "Shared", "StreamEventsConfig.luau"), "r", encoding="utf-8") as f:
        stream_events_src = f.read()
    with open(os.path.join(src_dir, "Shared", "ShopConfig.luau"), "r", encoding="utf-8") as f:
        shop_config_src = f.read()
    with open(os.path.join(src_dir, "Shared", "EnvironmentConfig.luau"), "r", encoding="utf-8") as f:
        environment_config_src = f.read()
    with open(os.path.join(src_dir, "Server", "Leaderstats.server.luau"), "r", encoding="utf-8") as f:
        leaderstats_src = f.read()
    with open(os.path.join(src_dir, "Server", "StreamManager.server.luau"), "r", encoding="utf-8") as f:
        stream_manager_src = f.read()
    with open(os.path.join(src_dir, "Server", "ShopManager.server.luau"), "r", encoding="utf-8") as f:
        shop_manager_src = f.read()
    with open(os.path.join(src_dir, "Server", "EventManager.server.luau"), "r", encoding="utf-8") as f:
        event_manager_src = f.read()
    with open(os.path.join(src_dir, "Server", "LeaderboardManager.server.luau"), "r", encoding="utf-8") as f:
        leaderboard_manager_src = f.read()
    with open(os.path.join(src_dir, "Server", "VehicleManager.server.luau"), "r", encoding="utf-8") as f:
        vehicle_manager_src = f.read()
    with open(os.path.join(src_dir, "Server", "EnvironmentManager.server.luau"), "r", encoding="utf-8") as f:
        environment_manager_src = f.read()
    with open(os.path.join(src_dir, "Client", "StreamGui.client.luau"), "r", encoding="utf-8") as f:
        stream_gui_src = f.read()
    with open(os.path.join(src_dir, "Client", "StreamController.client.luau"), "r", encoding="utf-8") as f:
        stream_controller_src = f.read()
    with open(os.path.join(src_dir, "Client", "PlatformSelectGui.client.luau"), "r", encoding="utf-8") as f:
        platform_select_gui_src = f.read()
    with open(os.path.join(src_dir, "Client", "StreamEventGui.client.luau"), "r", encoding="utf-8") as f:
        stream_event_gui_src = f.read()
    with open(os.path.join(src_dir, "Client", "ShopGui.client.luau"), "r", encoding="utf-8") as f:
        shop_gui_src = f.read()
    with open(os.path.join(src_dir, "Client", "VehicleGui.client.luau"), "r", encoding="utf-8") as f:
        vehicle_gui_src = f.read()
    with open(os.path.join(src_dir, "Client", "CityWaypoints.client.luau"), "r", encoding="utf-8") as f:
        city_waypoints_src = f.read()
    with open(os.path.join(src_dir, "Client", "RobuxStoreGui.client.luau"), "r", encoding="utf-8") as f:
        robux_store_gui_src = f.read()

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
        prompt_counter[0] += 1
        pid = f"RBX_{prompt_name}_{prompt_counter[0]}"
        return f'''
				<Item class="ProximityPrompt" referent="{pid}">
					<Properties>
						<string name="Name">{prompt_name}</string>
						<string name="ObjectText">{object_text}</string>
						<string name="ActionText">{action_text}</string>
						<float name="MaxActivationDistance">12</float>
						<float name="HoldDuration">0</float>
						<token name="KeyboardKeyCode">101</token>
						<bool name="RequiresLineOfSight">false</bool>
					</Properties>
				</Item>''' + label_children(badge_text, bg_color, stroke_color)

    city_parts = []

    # =========================================================================
    # 1. GROUND & MAIN CITY ROAD NETWORK
    # =========================================================================
    city_parts.append(make_part("CityGround", (1024, 4, 1024), (0, -2, 80), color=GRASS_GREEN, material=1280))

    # Main Avenue Road (Asphalt: X from -14 to +14, Z from -70 to 220, Length 290)
    city_parts.append(make_part("MainRoadAsphalt", (28, 0.4, 290), (0, 0.2, 75), color=ROAD_ASPHALT, material=256))

    # Yellow Center Dividing Double Lines
    for z_line in range(-60, 210, 16):
        city_parts.append(make_part("RoadCenterLine", (0.5, 0.42, 10), (0, 0.22, z_line), color=ROAD_MARK_YELLOW, material=288))

    # White Edge Lines
    city_parts.append(make_part("RoadEdgeL", (0.5, 0.42, 288), (-13, 0.22, 75), color=ROAD_MARK_WHITE, material=256))
    city_parts.append(make_part("RoadEdgeR", (0.5, 0.42, 288), (13, 0.22, 75), color=ROAD_MARK_WHITE, material=256))

    # Sidewalks with Curbs
    city_parts.append(make_part("SidewalkLeft", (10, 0.8, 290), (-19, 0.4, 75), color=SIDEWALK_GREY, material=800))
    city_parts.append(make_part("SidewalkRight", (10, 0.8, 290), (19, 0.4, 75), color=SIDEWALK_GREY, material=800))

    # Streetlights along the avenue
    for z_light in [-40, 20, 80, 140, 200]:
        city_parts.append(make_part("StreetPoleL", (0.6, 14, 0.6), (-23, 7, z_light), color=DESK_LEGS, material=800))
        city_parts.append(make_part("StreetArmL", (5, 0.5, 0.5), (-20.5, 13.8, z_light), color=DESK_LEGS, material=800))
        city_parts.append(make_part("StreetLampL", (1.2, 0.4, 1.2), (-18.2, 13.6, z_light), color=4294967295, material=288,
                                    light=("PointLight", (1.0, 0.95, 0.8), 2.2, 28)))
        city_parts.append(make_part("StreetPoleR", (0.6, 14, 0.6), (23, 7, z_light), color=DESK_LEGS, material=800))
        city_parts.append(make_part("StreetArmR", (5, 0.5, 0.5), (20.5, 13.8, z_light), color=DESK_LEGS, material=800))
        city_parts.append(make_part("StreetLampR", (1.2, 0.4, 1.2), (18.2, 13.6, z_light), color=4294967295, material=288,
                                    light=("PointLight", (1.0, 0.95, 0.8), 2.2, 28)))

    # Decorative Street Trees along Sidewalk
    for z_tree in [-20, 40, 100, 160]:
        # Left Tree
        city_parts.append(make_part("TreeTrunkL", (1.2, 8, 1.2), (-22, 4, z_tree), color=WOOD_FLOOR, material=272))
        city_parts.append(make_part("TreeLeavesL", (6, 6, 6), (-22, 10, z_tree), color=4281896740, material=1280))
        # Right Tree
        city_parts.append(make_part("TreeTrunkR", (1.2, 8, 1.2), (22, 4, z_tree), color=WOOD_FLOOR, material=272))
        city_parts.append(make_part("TreeLeavesR", (6, 6, 6), (22, 10, z_tree), color=4281896740, material=1280))

    # Decorative City Skyline Buildings
    city_parts.append(make_part("CityBuilding1", (40, 60, 40), (70, 30, -20), color=DARK_WALL, material=256))
    city_parts.append(make_part("CityBuilding2", (36, 85, 36), (-70, 42.5, -20), color=CEILING_COLOR, material=256))
    city_parts.append(make_part("CityBuilding3", (45, 50, 40), (75, 25, 120), color=CEILING_COLOR, material=256))

    # =========================================================================
    # 2. STREAMER HOUSE & DRIVEWAY (At Z = -50 to -74)
    # =========================================================================
    # Driveway / Parking Bay
    city_parts.append(make_part("HouseDriveway", (16, 0.5, 26), (14, 0.25, -45), color=ROAD_ASPHALT, material=256))
    city_parts.append(make_part("ParkingMarkerL", (0.4, 0.52, 16), (7.5, 0.26, -42), color=ROAD_MARK_WHITE, material=256))
    city_parts.append(make_part("ParkingMarkerR", (0.4, 0.52, 16), (20.5, 0.26, -42), color=ROAD_MARK_WHITE, material=256))

    # House Structure
    city_parts.append(make_part("RoomFloor", (28, 1, 24), (0, 0.5, -62), color=WOOD_FLOOR, material=272))
    city_parts.append(make_part("RoomCeiling", (28, 1, 24), (0, 12.5, -62), color=CEILING_COLOR, material=256))
    city_parts.append(make_part("BackWall", (28, 12, 1), (0, 6.5, -74), color=DARK_WALL, material=256))
    city_parts.append(make_part("LeftWall", (1, 12, 24), (-13.5, 6.5, -62), color=DARK_WALL, material=256))
    city_parts.append(make_part("RightWall", (1, 12, 24), (13.5, 6.5, -62), color=DARK_WALL, material=256))
    city_parts.append(make_part("FrontWallL", (10, 12, 1), (-9, 6.5, -50), color=DARK_WALL, material=256))
    city_parts.append(make_part("FrontWallR", (10, 12, 1), (9, 6.5, -50), color=DARK_WALL, material=256))
    city_parts.append(make_part("FrontWallTop", (8, 4, 1), (0, 10.5, -50), color=DARK_WALL, material=256))
    city_parts.append(make_part("HouseRoofAccent", (30, 1.2, 26), (0, 13.1, -62), color=4280295454, material=256))
    city_parts.append(make_part("HousePorchLight", (1, 1, 1), (0, 8.5, -49.4), color=4294967295, material=288,
                                light=("PointLight", (1, 0.9, 0.7), 1.8, 16)))

    # Studio Interior Inside House
    for px in [-8, -4, 0, 4, 8]:
        for py in [6.5, 9.5]:
            city_parts.append(make_part("AcousticPanel", (3.2, 2.2, 0.2), (px, py, -73.4), color=4280427045, material=800))

    city_parts.append(make_part("NeonStrip_TopBack", (26, 0.2, 0.2), (0, 11.9, -73.4), color=RGB_CYAN, material=288,
                                light=("PointLight", (0.2, 0.8, 1.0), 1.5, 20)))
    city_parts.append(make_part("NeonStrip_TopLeft", (0.2, 0.2, 22), (-12.9, 11.9, -62), color=RGB_PURPLE, material=288,
                                light=("PointLight", (0.7, 0.2, 1.0), 1.5, 20)))

    city_parts.append(make_part("StreamerRug", (12, 0.05, 10), (0, 1.03, -66), color=RUG_COLOR, material=816))

    # Desk Setup with ProximityPrompt on Desk
    desk_prompt_xml = '''
				<Item class="ProximityPrompt" referent="RBX_DeskPrompt">
					<Properties>
						<string name="Name">DeskPrompt</string>
						<string name="ObjectText">Streaming Battlestation</string>
						<string name="ActionText">Start / Manage Stream (E)</string>
						<float name="MaxActivationDistance">10</float>
						<float name="HoldDuration">0</float>
						<token name="KeyboardKeyCode">101</token>
						<bool name="RequiresLineOfSight">false</bool>
					</Properties>
				</Item>'''
    city_parts.append(make_part("DeskTop", (10, 0.3, 4.5), (0, 4.5, -70), color=DESK_TOP, material=256, children_xml=desk_prompt_xml))
    city_parts.append(make_part("DeskLegL", (0.4, 3.5, 4.2), (-4.6, 2.75, -70), color=DESK_LEGS, material=800))
    city_parts.append(make_part("DeskLegR", (0.4, 3.5, 4.2), (4.6, 2.75, -70), color=DESK_LEGS, material=800))
    city_parts.append(make_part("DeskLED", (9, 0.1, 0.1), (0, 4.4, -68.5), color=RGB_CYAN, material=288,
                                light=("PointLight", (0.2, 0.8, 1.0), 1.0, 10)))

    # PC Tower & Monitors
    city_parts.append(make_part("PCCase", (1.2, 2.4, 2.2), (3.8, 5.85, -69.5), color=4280295454, material=256))
    city_parts.append(make_part("PCGlassPanel", (0.05, 2.2, 2.0), (3.18, 5.85, -69.5), color=4283549695, material=304, transparency=0.4))
    city_parts.append(make_part("PC_RGB_Fan1", (0.1, 0.8, 0.8), (3.5, 6.3, -68.4), color=RGB_PURPLE, material=288))
    city_parts.append(make_part("PC_RGB_Fan2", (0.1, 0.8, 0.8), (3.5, 5.3, -68.4), color=RGB_CYAN, material=288))

    city_parts.append(make_part("MainMonitorStand", (0.4, 1.2, 0.4), (0, 5.25, -70.6), color=DESK_LEGS, material=800))
    city_parts.append(make_part("MainMonitorBezel", (4.2, 2.3, 0.15), (0, 6.2, -70.6), color=DESK_LEGS, material=256))
    city_parts.append(make_part("MainMonitorScreen", (4.0, 2.1, 0.05), (0, 6.2, -70.5), color=SCREEN_COLOR, material=288,
                                light=("PointLight", (0.4, 0.6, 1.0), 0.8, 6)))
    city_parts.append(make_part("LeftMonitorBezel", (3.2, 2.1, 0.15), (-3.4, 6.2, -70.2), rot=(0, 25, 0), color=DESK_LEGS, material=256))
    city_parts.append(make_part("LeftMonitorScreen", (3.0, 1.9, 0.05), (-3.35, 6.2, -70.1), rot=(0, 25, 0), color=RGB_CYAN, material=288))

    city_parts.append(make_part("Webcam", (0.6, 0.25, 0.3), (0, 7.45, -70.5), color=DESK_LEGS, material=256))
    city_parts.append(make_part("MousePad", (5.5, 0.04, 2.2), (0, 4.67, -69.0), color=4280826955, material=816))
    city_parts.append(make_part("RGBKeyboard", (2.6, 0.12, 1.0), (-0.8, 4.75, -69.0), color=DESK_LEGS, material=256))
    city_parts.append(make_part("GamingMouse", (0.5, 0.15, 0.8), (1.4, 4.75, -69.0), color=DESK_LEGS, material=256))
    city_parts.append(make_part("MicClamp", (0.3, 0.4, 0.3), (-3.2, 4.8, -68.5), color=DESK_LEGS, material=800))
    city_parts.append(make_part("MicBody", (0.3, 0.6, 0.3), (-1.4, 5.8, -68.9), color=4280427045, material=800))

    # Grounded Gaming Chair with ProximityPrompt
    chair_prompt_xml = '''
				<Item class="ProximityPrompt" referent="RBX_ChairSitPrompt">
					<Properties>
						<string name="Name">SitPrompt</string>
						<string name="ObjectText">Streamer Chair</string>
						<string name="ActionText">Sit &amp; Stream (E)</string>
						<float name="MaxActivationDistance">10</float>
						<float name="HoldDuration">0</float>
						<token name="KeyboardKeyCode">101</token>
						<bool name="RequiresLineOfSight">false</bool>
					</Properties>
				</Item>'''
    city_parts.append(make_part("ChairWheelBase1", (2.4, 0.2, 0.4), (0, 1.2, -67.0), color=DESK_LEGS, material=800))
    city_parts.append(make_part("ChairWheelBase2", (0.4, 0.2, 2.4), (0, 1.2, -67.0), color=DESK_LEGS, material=800))
    city_parts.append(make_part("ChairWheel1", (0.3, 0.3, 0.3), (1.0, 1.2, -67.0), color=DESK_LEGS, material=256))
    city_parts.append(make_part("ChairWheel2", (0.3, 0.3, 0.3), (-1.0, 1.2, -67.0), color=DESK_LEGS, material=256))
    city_parts.append(make_part("ChairPiston", (0.35, 1.0, 0.35), (0, 1.75, -67.0), color=4289374890, material=800))
    city_parts.append(make_part("GamingChairSeat", (2.2, 0.4, 2.2), (0, 2.4, -67.0), color=CHAIR_BLACK, material=816, is_seat=True, children_xml=chair_prompt_xml))
    city_parts.append(make_part("ChairBackrest", (2.0, 2.8, 0.35), (0, 3.8, -65.9), rot=(-5, 0, 0), color=CHAIR_BLACK, material=816))
    city_parts.append(make_part("ChairHeadrest", (1.4, 0.7, 0.3), (0, 5.3, -65.8), rot=(-5, 0, 0), color=CHAIR_RED, material=816))
    city_parts.append(make_part("ChairLumbarPillow", (1.2, 0.5, 0.25), (0, 2.9, -66.0), rot=(-5, 0, 0), color=CHAIR_RED, material=816))
    city_parts.append(make_part("ChairArmPostL", (0.15, 0.8, 0.15), (-1.15, 2.7, -67.0), color=DESK_LEGS, material=800))
    city_parts.append(make_part("ChairArmPadL", (0.3, 0.15, 1.2), (-1.15, 3.15, -67.0), color=CHAIR_BLACK, material=816))
    city_parts.append(make_part("ChairArmPostR", (0.15, 0.8, 0.15), (1.15, 2.7, -67.0), color=DESK_LEGS, material=800))
    city_parts.append(make_part("ChairArmPadR", (0.3, 0.15, 1.2), (1.15, 3.15, -67.0), color=CHAIR_BLACK, material=816))

    # Trophies & Ceiling Light
    city_parts.append(make_part("ShelfFrame", (2.0, 8.0, 6.0), (12.2, 5.5, -65.0), color=4280295454, material=256))
    city_parts.append(make_part("TrophyCup", (0.5, 0.8, 0.5), (12.2, 6.8, -66.5), color=GOLD_COLOR, material=800))
    city_parts.append(make_part("CeilingLightPanel", (6.0, 0.1, 6.0), (0, 11.9, -62), color=4294967295, material=288,
                                light=("PointLight", (1.0, 0.95, 0.9), 1.8, 30)))

    # =========================================================================
    # 3. DRIVABLE GALAXY HOVERBOARD (Parked in Driveway at X=14, Z=-42)
    # =========================================================================
    hoverboard_parts = []

    # Deck (root/chassis) with RidePrompt ProximityPrompt and 3D Badge
    hoverboard_children = '''
				<Item class="ProximityPrompt" referent="RBX_HoverRidePrompt">
					<Properties>
						<string name="Name">RidePrompt</string>
						<string name="ObjectText">Galaxy Hoverboard</string>
						<string name="ActionText">Ride (E)</string>
						<float name="MaxActivationDistance">10</float>
						<float name="HoldDuration">0</float>
						<token name="KeyboardKeyCode">101</token>
						<bool name="RequiresLineOfSight">false</bool>
					</Properties>
				</Item>
				<Item class="BillboardGui" referent="RBX_HoverBadge">
					<Properties>
						<string name="Name">HoverBadge</string>
						<Vector3 name="StudsOffset"><X>0</X><Y>2.6</Y><Z>0</Z></Vector3>
						<UDim2 name="Size"><XS>0</XS><XO>190</XO><YS>0</YS><YO>42</YO></UDim2>
						<bool name="AlwaysOnTop">true</bool>
						<float name="MaxDistance">90</float>
						<float name="LightInfluence">0</float>
					</Properties>
					<Item class="Frame" referent="RBX_HoverBadgeF">
						<Properties>
							<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO></UDim2>
							<Color3 name="BackgroundColor3"><R>0.08</R><G>0.1</G><B>0.14</B></Color3>
							<float name="BackgroundTransparency">0.2</float>
						</Properties>
						<Item class="UICorner" referent="RBX_HoverBadgeC">
							<Properties><UDim name="CornerRadius"><S>0</S><O>10</O></UDim></Properties>
						</Item>
						<Item class="UIStroke" referent="RBX_HoverBadgeS">
							<Properties>
								<Color3 name="Color"><R>0.235</R><G>0.667</G><B>1</B></Color3>
								<float name="Thickness">2</float>
							</Properties>
						</Item>
						<Item class="TextLabel" referent="RBX_HoverBadgeL">
							<Properties>
								<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO></UDim2>
								<float name="BackgroundTransparency">1</float>
								<string name="Text">🛹 Galaxy Hoverboard [E]</string>
								<Color3 name="TextColor3"><R>1</R><G>1</G><B>1</B></Color3>
								<token name="Font">17</token>
								<float name="TextSize">14</float>
							</Properties>
						</Item>
					</Item>
				</Item>'''

    # Немає VehicleSeat/Seat навмисно: ці класи в Roblox автоматично саджають
    # гравця, щойно він торкнеться деталі, а нам потрібно, щоб персонаж СТОЯВ
    # на дошці (керування реалізоване вручну через ProximityPrompt + сервер).
    hoverboard_parts.append(make_part("HoverboardBody", (1.6, 0.3, 4.4), (14, 2.0, -42), color=HOVER_NAVY_DARK, material=256, anchored=True, can_collide=True, children_xml=hoverboard_children))

    # Deco "galaxy" stripe + grip footpads (can_collide=False, welded to the deck)
    hoverboard_parts.append(make_part("GalaxyAccent", (0.6, 0.05, 3.8), (14, 2.16, -42), color=RGB_PURPLE, material=256, anchored=True, can_collide=False))
    hoverboard_parts.append(make_part("FootpadFront", (1.3, 0.08, 1.5), (14, 2.19, -43.4), color=HOVER_GRIP_BLACK, material=816, anchored=True, can_collide=False))
    hoverboard_parts.append(make_part("FootpadBack", (1.3, 0.08, 1.5), (14, 2.19, -40.6), color=HOVER_GRIP_BLACK, material=816, anchored=True, can_collide=False))

    # Blue LED strips along both edges (Neon + soft glow, matches reference photo)
    hoverboard_parts.append(make_part("LedStripL", (0.1, 0.12, 4.2), (13.15, 2.0, -42), color=HOVER_LED_BLUE, material=288, anchored=True, can_collide=False,
                               light=("PointLight", (0.3, 0.65, 1), 2.0, 16)))
    hoverboard_parts.append(make_part("LedStripR", (0.1, 0.12, 4.2), (14.85, 2.0, -42), color=HOVER_LED_BLUE, material=288, anchored=True, can_collide=False,
                               light=("PointLight", (0.3, 0.65, 1), 2.0, 16)))

    # Wheels (cylinders, can_collide=True for ground contact)
    # rot=(0,90,0): вісь колеса розвернута так, щоб воно котилось УБІК (вздовж X,
    # куди тепер дивиться персонаж), а не вперед-назад як у машини (вздовж Z).
    hoverboard_parts.append(make_part("WheelFront", (0.4, 1.0, 1.0), (14, 1.4, -44.0), rot=(0, 90, 0), color=HOVER_WHEEL_BLACK, material=256, anchored=True, can_collide=True, shape=2))
    hoverboard_parts.append(make_part("WheelBack", (0.4, 1.0, 1.0), (14, 1.4, -40.0), rot=(0, 90, 0), color=HOVER_WHEEL_BLACK, material=256, anchored=True, can_collide=True, shape=2))

    hoverboard_model_xml = f'''
		<Item class="Model" referent="RBX_Hoverboard">
			<Properties>
				<string name="Name">Hoverboard</string>
			</Properties>
			{"".join(hoverboard_parts)}
		</Item>'''

    # =========================================================================
    # 4. TECH STORE ("CyberByte Tech Store" at X = 46, Z = 40)
    # =========================================================================
    city_parts.append(make_part("TechStoreFloor", (36, 1, 32), (46, 0.5, 40), color=DARK_WALL, material=256))
    city_parts.append(make_part("TechStoreRoof", (38, 1.5, 34), (46, 16.5, 40), color=DARK_WALL, material=256))
    city_parts.append(make_part("TechStoreBackWall", (1, 15, 32), (64.5, 8.5, 40), color=DARK_WALL, material=256))
    city_parts.append(make_part("TechStoreSideWall1", (36, 15, 1), (46, 8.5, 23.5), color=DARK_WALL, material=256))
    city_parts.append(make_part("TechStoreSideWall2", (36, 15, 1), (46, 8.5, 56.5), color=DARK_WALL, material=256))
    city_parts.append(make_part("TechStoreGlassFront", (1, 15, 20), (27.5, 8.5, 40), color=RGB_CYAN, material=304, transparency=0.4))
    city_parts.append(make_part("TechStoreSignBoard", (1, 3.5, 24), (27.0, 17.5, 40), color=DARK_WALL, material=256))
    city_parts.append(make_part("TechStoreSignNeon", (0.2, 2.5, 23), (26.4, 17.5, 40), color=RGB_CYAN, material=288,
                                light=("PointLight", (0.2, 0.8, 1.0), 2.5, 30)))

    # Tech Counter with ProximityPrompt & 3D Billboard
    tech_counter_children = '''
				<Item class="ProximityPrompt" referent="RBX_TechPrompt">
					<Properties>
						<string name="Name">TechPrompt</string>
						<string name="ObjectText">CyberByte Tech Store</string>
						<string name="ActionText">Browse Hardware &amp; Games (E)</string>
						<float name="MaxActivationDistance">12</float>
						<float name="HoldDuration">0</float>
						<token name="KeyboardKeyCode">101</token>
						<bool name="RequiresLineOfSight">false</bool>
					</Properties>
				</Item>
				<Item class="BillboardGui" referent="RBX_TechBadge">
					<Properties>
						<string name="Name">TechBadge</string>
						<Vector3 name="StudsOffset"><X>0</X><Y>3.5</Y><Z>0</Z></Vector3>
						<UDim2 name="Size"><XS>0</XS><XO>210</XO><YS>0</YS><YO>46</YO></UDim2>
						<bool name="AlwaysOnTop">true</bool>
						<float name="MaxDistance">80</float>
						<float name="LightInfluence">0</float>
					</Properties>
					<Item class="Frame" referent="RBX_TechBadgeF">
						<Properties>
							<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO></UDim2>
							<Color3 name="BackgroundColor3"><R>0.08</R><G>0.12</G><B>0.18</B></Color3>
							<float name="BackgroundTransparency">0.2</float>
						</Properties>
						<Item class="UICorner" referent="RBX_TechBadgeC">
							<Properties><UDim name="CornerRadius"><S>0</S><O>10</O></UDim></Properties>
						</Item>
						<Item class="UIStroke" referent="RBX_TechBadgeS">
							<Properties>
								<Color3 name="Color"><R>0.2</R><G>0.8</G><B>1</B></Color3>
								<float name="Thickness">2</float>
							</Properties>
						</Item>
						<Item class="TextLabel" referent="RBX_TechBadgeL">
							<Properties>
								<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO></UDim2>
								<float name="BackgroundTransparency">1</float>
								<string name="Text">💻 CyberByte Tech [E]</string>
								<Color3 name="TextColor3"><R>1</R><G>1</G><B>1</B></Color3>
								<token name="Font">17</token>
								<float name="TextSize">15</float>
							</Properties>
						</Item>
					</Item>
				</Item>'''
    city_parts.append(make_part("TechCounter", (14, 3.5, 2.5), (46, 2.25, 42), color=DESK_TOP, material=256, children_xml=tech_counter_children))
    city_parts.append(make_part("TechShowcaseGlass", (13.6, 1.5, 0.2), (46, 4.75, 42), color=RGB_CYAN, material=304, transparency=0.4))
    city_parts.append(make_part("TechShowcasePC1", (1.4, 2.4, 2.2), (43, 3.0, 32), color=DESK_LEGS, material=256))
    city_parts.append(make_part("TechShowcasePC2", (1.4, 2.4, 2.2), (48, 3.0, 32), color=CHAIR_RED, material=256))

    # =========================================================================
    # 5. GROCERY STORE ("Burger & Snacks Mart" at X = -46, Z = 40)
    # =========================================================================
    city_parts.append(make_part("GroceryFloor", (36, 1, 32), (-46, 0.5, 40), color=DARK_WALL, material=256))
    city_parts.append(make_part("GroceryRoof", (38, 1.5, 34), (-46, 16.5, 40), color=DARK_WALL, material=256))
    city_parts.append(make_part("GroceryBackWall", (1, 15, 32), (-64.5, 8.5, 40), color=DARK_WALL, material=256))
    city_parts.append(make_part("GrocerySideWall1", (36, 15, 1), (-46, 8.5, 23.5), color=DARK_WALL, material=256))
    city_parts.append(make_part("GrocerySideWall2", (36, 15, 1), (-46, 8.5, 56.5), color=DARK_WALL, material=256))
    city_parts.append(make_part("GroceryGlassFront", (1, 15, 20), (-27.5, 8.5, 40), color=GOLD_COLOR, material=304, transparency=0.4))
    city_parts.append(make_part("GrocerySignBoard", (1, 3.5, 24), (-27.0, 17.5, 40), color=DARK_WALL, material=256))
    city_parts.append(make_part("GrocerySignNeon", (0.2, 2.5, 23), (-26.4, 17.5, 40), color=GOLD_COLOR, material=288,
                                light=("PointLight", (1.0, 0.8, 0.2), 2.5, 30)))

    # Food Counter with ProximityPrompt & 3D Billboard
    grocery_counter_children = '''
				<Item class="ProximityPrompt" referent="RBX_GroceryPrompt">
					<Properties>
						<string name="Name">GroceryPrompt</string>
						<string name="ObjectText">Burger &amp; Snacks Mart</string>
						<string name="ActionText">Buy Energy Drinks &amp; Food (E)</string>
						<float name="MaxActivationDistance">12</float>
						<float name="HoldDuration">0</float>
						<token name="KeyboardKeyCode">101</token>
						<bool name="RequiresLineOfSight">false</bool>
					</Properties>
				</Item>
				<Item class="BillboardGui" referent="RBX_GroceryBadge">
					<Properties>
						<string name="Name">GroceryBadge</string>
						<Vector3 name="StudsOffset"><X>0</X><Y>3.5</Y><Z>0</Z></Vector3>
						<UDim2 name="Size"><XS>0</XS><XO>210</XO><YS>0</YS><YO>46</YO></UDim2>
						<bool name="AlwaysOnTop">true</bool>
						<float name="MaxDistance">80</float>
						<float name="LightInfluence">0</float>
					</Properties>
					<Item class="Frame" referent="RBX_GroceryBadgeF">
						<Properties>
							<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO></UDim2>
							<Color3 name="BackgroundColor3"><R>0.18</R><G>0.12</G><B>0.06</B></Color3>
							<float name="BackgroundTransparency">0.2</float>
						</Properties>
						<Item class="UICorner" referent="RBX_GroceryBadgeC">
							<Properties><UDim name="CornerRadius"><S>0</S><O>10</O></UDim></Properties>
						</Item>
						<Item class="UIStroke" referent="RBX_GroceryBadgeS">
							<Properties>
								<Color3 name="Color"><R>1</R><G>0.7</G><B>0.1</B></Color3>
								<float name="Thickness">2</float>
							</Properties>
						</Item>
						<Item class="TextLabel" referent="RBX_GroceryBadgeL">
							<Properties>
								<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO></UDim2>
								<float name="BackgroundTransparency">1</float>
								<string name="Text">🍔 Burger Mart [E]</string>
								<Color3 name="TextColor3"><R>1</R><G>1</G><B>1</B></Color3>
								<token name="Font">17</token>
								<float name="TextSize">15</float>
							</Properties>
						</Item>
					</Item>
				</Item>'''
    city_parts.append(make_part("GroceryCounter", (14, 3.5, 2.5), (-46, 2.25, 42), color=WOOD_FLOOR, material=272, children_xml=grocery_counter_children))

    # =========================================================================
    # 6. TOWN SQUARE & LEADERBOARD CORNER (At X = -46, Z = 130)
    # =========================================================================
    city_parts.append(make_part("TownSquarePlaza", (40, 0.8, 40), (-46, 0.4, 130), color=TECH_PLAZA, material=800))
    city_parts.append(make_part("LB_StandL", (1.0, 15, 1.0), (-52, 7.5, 142), color=DESK_LEGS, material=800))
    city_parts.append(make_part("LB_StandR", (1.0, 15, 1.0), (-40, 7.5, 142), color=DESK_LEGS, material=800))
    city_parts.append(make_part("LB_BackPanel", (15, 11, 0.5), (-46, 9.5, 142.3), color=DARK_WALL, material=256))
    city_parts.append(make_part("LB_NeonGlow", (15.4, 11.4, 0.1), (-46, 9.5, 142.35), color=GOLD_COLOR, material=288,
                                light=("PointLight", (1.0, 0.85, 0.0), 2.0, 22)))

    # =========================================================================
    # 7. NORTH AVENUE — продовження головної дороги на північ, до нових районів
    #    (Vehicle Shop, Pool, Zoo, Colosseum). Стикується з MainRoadAsphalt (Z до 220).
    #    Подовжена вперед аж до воріт Колізею (Z~500), щоб вулиця виразно "вела" до нього.
    # =========================================================================
    NAVE_LEN = 250
    NAVE_CZ = 220 + NAVE_LEN / 2
    city_parts.append(make_part("NorthAvenueAsphalt", (28, 0.4, NAVE_LEN), (0, 0.2, NAVE_CZ), color=ROAD_ASPHALT, material=256))
    for z_line in range(230, 465, 16):
        city_parts.append(make_part("NorthAveCenterLine", (0.5, 0.42, 10), (0, 0.22, z_line), color=ROAD_MARK_YELLOW, material=288))
    city_parts.append(make_part("NorthAveEdgeL", (0.5, 0.42, NAVE_LEN - 2), (-13, 0.22, NAVE_CZ), color=ROAD_MARK_WHITE, material=256))
    city_parts.append(make_part("NorthAveEdgeR", (0.5, 0.42, NAVE_LEN - 2), (13, 0.22, NAVE_CZ), color=ROAD_MARK_WHITE, material=256))
    city_parts.append(make_part("NorthAveSidewalkL", (10, 0.8, NAVE_LEN), (-19, 0.4, NAVE_CZ), color=SIDEWALK_GREY, material=800))
    city_parts.append(make_part("NorthAveSidewalkR", (10, 0.8, NAVE_LEN), (19, 0.4, NAVE_CZ), color=SIDEWALK_GREY, material=800))
    for z_light in (250, 320, 390, 460):
        city_parts.append(make_part("NAvePoleL", (0.6, 14, 0.6), (-23, 7, z_light), color=DESK_LEGS, material=800))
        city_parts.append(make_part("NAveLampL", (1.2, 0.4, 1.2), (-20.5, 13.6, z_light), color=4294967295, material=288,
                                    light=("PointLight", (1.0, 0.9, 0.6), 2.2, 26)))
        city_parts.append(make_part("NAvePoleR", (0.6, 14, 0.6), (23, 7, z_light), color=DESK_LEGS, material=800))
        city_parts.append(make_part("NAveLampR", (1.2, 0.4, 1.2), (20.5, 13.6, z_light), color=4294967295, material=288,
                                    light=("PointLight", (1.0, 0.9, 0.6), 2.2, 26)))

    # =========================================================================
    # 8. VEHICLE SHOP — "SkyGlide Board Shop" (окремий магазин гіроскутерів, X=46, Z=250)
    #    Та сама generic ShopConfig-система: тут просто інша ProximityPrompt ("VehiclePrompt"),
    #    яку відкриває ShopGui.client.luau (потрібно додати назву промпта в клієнтський скрипт).
    # =========================================================================
    city_parts.append(make_part("VShopFloor", (36, 1, 32), (46, 0.5, 250), color=DARK_WALL, material=256))
    city_parts.append(make_part("VShopRoof", (38, 1.5, 34), (46, 16.5, 250), color=DARK_WALL, material=256))
    city_parts.append(make_part("VShopBackWall", (1, 15, 32), (64.5, 8.5, 250), color=DARK_WALL, material=256))
    city_parts.append(make_part("VShopSideWall1", (36, 15, 1), (46, 8.5, 233.5), color=DARK_WALL, material=256))
    city_parts.append(make_part("VShopSideWall2", (36, 15, 1), (46, 8.5, 266.5), color=DARK_WALL, material=256))
    city_parts.append(make_part("VShopGlassFront", (1, 15, 20), (27.5, 8.5, 250), color=HOVER_LED_BLUE, material=304, transparency=0.4))
    city_parts.append(make_part("VShopSignBoard", (1, 3.5, 24), (27.0, 17.5, 250), color=DARK_WALL, material=256))
    city_parts.append(make_part("VShopSignNeon", (0.2, 2.5, 23), (26.4, 17.5, 250), color=HOVER_LED_BLUE, material=288,
                                light=("PointLight", (0.3, 0.6, 1.0), 2.5, 30)))

    vshop_counter_children = shop_children(
        "VehiclePrompt",
        "SkyGlide Board Shop",
        "Купити гіроскутер (E)",
        "🛹 SkyGlide Boards [E]",
        bg_color=(0.08, 0.10, 0.20), stroke_color=(0.3, 0.6, 1.0))
    city_parts.append(make_part("VShopCounter", (14, 3.5, 2.5), (46, 2.25, 252), color=DESK_TOP, material=256, children_xml=vshop_counter_children))
    city_parts.append(make_part("VShopShowcaseGlass", (13.6, 1.5, 0.2), (46, 4.75, 252), color=HOVER_LED_BLUE, material=304, transparency=0.4))
    # Демонстраційні дошки на підставках у вітрині
    city_parts.append(make_part("VShopDisplayBoard1", (1.4, 0.25, 3.8), (40, 2.3, 240), color=HOVER_NAVY_DARK, material=256))
    city_parts.append(make_part("VShopDisplayGlow1", (0.5, 0.05, 3.2), (40, 2.44, 240), color=RGB_PURPLE, material=288))
    city_parts.append(make_part("VShopDisplayBoard2", (1.4, 0.25, 3.8), (52, 2.3, 240), color=HOVER_NAVY_DARK, material=256))
    city_parts.append(make_part("VShopDisplayGlow2", (0.5, 0.05, 3.2), (52, 2.44, 240), color=HOVER_LED_BLUE, material=288))

    # =========================================================================
    # 9. SPLASH STREET POOL — міський басейн для стрімів (X=-46, Z=250)
    # =========================================================================
    city_parts.append(make_part("PoolDeck", (44, 1, 36), (-46, 0.5, 250), color=POOL_TILE, material=256))
    city_parts.append(make_part("PoolWater", (30, 1, 20), (-46, 0.55, 250), color=POOL_WATER, material=304, transparency=0.25, can_collide=False))
    city_parts.append(make_part("PoolBorderN", (32, 0.4, 1), (-46, 0.7, 240), color=POOL_TILE_BLUE, material=256))
    city_parts.append(make_part("PoolBorderS", (32, 0.4, 1), (-46, 0.7, 260), color=POOL_TILE_BLUE, material=256))
    city_parts.append(make_part("PoolBorderE", (1, 0.4, 20), (-30, 0.7, 250), color=POOL_TILE_BLUE, material=256))
    city_parts.append(make_part("PoolBorderW", (1, 0.4, 20), (-62, 0.7, 250), color=POOL_TILE_BLUE, material=256))

    # Шезлонги вздовж північної (z=234, обличчям на південь до води) та південної (z=266) смуг деку
    lounge_spots = [(-60, 234, 0), (-52, 234, 0), (-40, 234, 0), (-32, 234, 0), (-60, 266, 180), (-32, 266, 180)]
    for i, (lx, lz, lry) in enumerate(lounge_spots):
        back_z = lz + (2.0 if lry == 0 else -2.0)
        city_parts.append(make_part(f"LoungeChair{i+1}", (2.0, 0.6, 4.4), (lx, 0.8, lz), rot=(0, lry, 0), color=POOL_TILE, material=816))
        city_parts.append(make_part(f"LoungeChairBack{i+1}", (2.0, 1.6, 0.3), (lx, 1.4, back_z), rot=(-20, lry, 0), color=POOL_TILE_BLUE, material=816))

    for i, (ux, uz) in enumerate([(-38, 238), (-54, 262)]):
        city_parts.append(make_part(f"PoolUmbrellaPole{i+1}", (0.3, 6.5, 0.3), (ux, 3.25, uz), shape=2, color=DESK_LEGS, material=800))
        city_parts.append(make_part(f"PoolUmbrellaCanopy{i+1}", (0.6, 6.5, 6.5), (ux, 6.6, uz), rot=(0, 0, 90), shape=2, color=RGB_CYAN if i == 0 else GOLD_COLOR, material=816))

    pool_sign_children = label_children("🏊 Splash Street Pool — Streaming Zone", bg_color=(0.06, 0.14, 0.22), stroke_color=(0.3, 0.75, 1.0))
    city_parts.append(make_part("PoolSignPost", (0.6, 8, 0.6), (-46, 4, 232), color=DESK_LEGS, material=800, children_xml=pool_sign_children))
    city_parts.append(make_part("PoolFenceGlassN", (32, 1.6, 0.15), (-46, 1.6, 233), color=POOL_TILE_BLUE, material=304, transparency=0.55))
    city_parts.append(make_part("PoolFenceGlassS", (32, 1.6, 0.15), (-46, 1.6, 267), color=POOL_TILE_BLUE, material=304, transparency=0.55))

    # =========================================================================
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

    # =========================================================================
    # 11. WILD STREAM ZOO — невеликий зоопарк для ІРЛ-стрімів (X=130, Z=320)
    # =========================================================================
    ZOO_CX, ZOO_CZ = 130, 320
    city_parts.append(make_part("ZooGround", (64, 0.6, 64), (ZOO_CX, 0.3, ZOO_CZ), color=ZOO_GRASS, material=1280))
    city_parts.append(make_part("ZooFenceN", (64, 3.4, 1), (ZOO_CX, 1.7, ZOO_CZ - 32), color=ZOO_FENCE, material=272))
    city_parts.append(make_part("ZooFenceS", (64, 3.4, 1), (ZOO_CX, 1.7, ZOO_CZ + 32), color=ZOO_FENCE, material=272))
    city_parts.append(make_part("ZooFenceE", (1, 3.4, 64), (ZOO_CX + 32, 1.7, ZOO_CZ), color=ZOO_FENCE, material=272))
    city_parts.append(make_part("ZooFenceW1", (1, 3.4, 20), (ZOO_CX - 32, 1.7, ZOO_CZ - 22), color=ZOO_FENCE, material=272))
    city_parts.append(make_part("ZooFenceW2", (1, 3.4, 20), (ZOO_CX - 32, 1.7, ZOO_CZ + 22), color=ZOO_FENCE, material=272))
    zoo_gate_children = label_children("🦁 Wild Stream Zoo — IRL Content Zone", bg_color=(0.08, 0.16, 0.06), stroke_color=(0.4, 0.9, 0.3), width=280)
    city_parts.append(make_part("ZooGatePost", (1.2, 8, 1.2), (ZOO_CX - 32, 4, ZOO_CZ), color=ZOO_FENCE, material=272, children_xml=zoo_gate_children))
    # Внутрішні перегородки на 4 вольєри
    city_parts.append(make_part("ZooDividerNS", (0.8, 2.8, 60), (ZOO_CX, 1.4, ZOO_CZ), color=ZOO_FENCE, material=272))
    city_parts.append(make_part("ZooDividerEW", (60, 2.8, 0.8), (ZOO_CX, 1.4, ZOO_CZ), color=ZOO_FENCE, material=272))

    # Лев (Lion) — X<CX, Z<CZ
    city_parts.append(make_part("LionBody", (3.2, 2.2, 5.2), (ZOO_CX - 16, 1.6, ZOO_CZ - 16), color=4294956800, material=816))
    city_parts.append(make_part("LionMane", (2.6, 2.6, 2.6), (ZOO_CX - 16, 2.3, ZOO_CZ - 18.5), shape=1, color=BRONZE_COLOR, material=816))
    city_parts.append(make_part("LionHead", (1.6, 1.6, 1.6), (ZOO_CX - 16, 2.3, ZOO_CZ - 18.5), shape=1, color=4294956800, material=816))
    city_parts.append(make_part("LionRock", (3, 1.4, 2), (ZOO_CX - 19, 0.7, ZOO_CZ - 12), shape=1, color=ZOO_ROCK, material=1296))

    # Жираф (Giraffe) — X>CX, Z<CZ
    city_parts.append(make_part("GiraffeLegs", (1.6, 5.5, 3.2), (ZOO_CX + 16, 2.75, ZOO_CZ - 16), color=4294956800, material=816))
    city_parts.append(make_part("GiraffeNeck", (1.0, 4.5, 1.0), (ZOO_CX + 16, 7.5, ZOO_CZ - 17.5), rot=(-15, 0, 0), color=4294956800, material=816))
    city_parts.append(make_part("GiraffeHead", (1.2, 1.4, 1.8), (ZOO_CX + 16, 9.7, ZOO_CZ - 19), color=4294956800, material=816))
    city_parts.append(make_part("GiraffeOssicone1", (0.2, 0.6, 0.2), (ZOO_CX + 15.6, 10.5, ZOO_CZ - 19.3), color=DESK_LEGS, material=816))
    city_parts.append(make_part("GiraffeOssicone2", (0.2, 0.6, 0.2), (ZOO_CX + 16.4, 10.5, ZOO_CZ - 19.3), color=DESK_LEGS, material=816))

    # Слон (Elephant) — X<CX, Z>CZ
    city_parts.append(make_part("ElephantBody", (4.4, 3.6, 6.4), (ZOO_CX - 16, 2.2, ZOO_CZ + 16), color=SIDEWALK_GREY, material=816))
    city_parts.append(make_part("ElephantHead", (2.6, 2.6, 2.0), (ZOO_CX - 16, 2.6, ZOO_CZ + 13), color=SIDEWALK_GREY, material=816))
    city_parts.append(make_part("ElephantTrunk", (0.7, 2.4, 0.7), (ZOO_CX - 16, 1.4, ZOO_CZ + 11.4), rot=(35, 0, 0), color=SIDEWALK_GREY, material=816))
    city_parts.append(make_part("ElephantEarL", (0.3, 1.8, 1.6), (ZOO_CX - 17.4, 2.9, ZOO_CZ + 13), color=DARK_WALL, material=816))
    city_parts.append(make_part("ElephantEarR", (0.3, 1.8, 1.6), (ZOO_CX - 14.6, 2.9, ZOO_CZ + 13), color=DARK_WALL, material=816))

    # Пінгвіни (Penguins) — X>CX, Z>CZ, з невеликим ставком
    city_parts.append(make_part("PenguinPond", (7, 0.5, 7), (ZOO_CX + 16, 0.25, ZOO_CZ + 16), rot=(0, 0, 90), shape=2, color=POOL_WATER, material=304, transparency=0.2))
    for i, (px, pz) in enumerate([(ZOO_CX + 14, ZOO_CZ + 20), (ZOO_CX + 18, ZOO_CZ + 21), (ZOO_CX + 16, ZOO_CZ + 19)]):
        city_parts.append(make_part(f"PenguinBody{i+1}", (0.8, 1.4, 0.8), (px, 0.9, pz), shape=1, color=4281545523, material=816))
        city_parts.append(make_part(f"PenguinBelly{i+1}", (0.5, 1.0, 0.4), (px, 0.9, pz - 0.3), color=4294967295, material=816))

    # =========================================================================
    # 12. CELEBRITY ROW — вулиця з розкішними особняками відомих стрімерів (на південь від будинку)
    # =========================================================================
    city_parts.append(make_part("CelebrityRowAsphalt", (28, 0.4, 190), (0, 0.2, -165), color=ROAD_ASPHALT, material=256))
    for z_line in range(-100, -255, -16):
        city_parts.append(make_part("CelebRowCenterLine", (0.5, 0.42, 10), (0, 0.22, z_line), color=ROAD_MARK_YELLOW, material=288))

    def build_mansion(cx, cz, label_text, accent_color, scale=1.0):
        w = 34 * scale
        d = 26 * scale
        h = 16 * scale
        parts = []
        parts.append(make_part(f"MansionFoundation_{cx}_{cz}", (w + 6, 0.6, d + 10), (cx, 0.3, cz), color=SIDEWALK_GREY, material=800))
        parts.append(make_part(f"MansionBody_{cx}_{cz}", (w, h, d), (cx, h / 2 + 0.6, cz), color=MANSION_WHITE, material=256))
        parts.append(make_part(f"MansionRoof_{cx}_{cz}", (w + 4, 1.6, d + 4), (cx, h + 1.4, cz), color=MANSION_ROOF_DARK, material=256))
        # Фасад дивиться на +Z (у бік проспекту Celebrity Row, який іде на північ до головної дороги)
        parts.append(make_part(f"MansionGlass_{cx}_{cz}", (w * 0.55, h * 0.55, 0.4), (cx, h * 0.5 + 0.6, cz + d / 2 + 0.3), color=GLASS_BLUE, material=304, transparency=0.35))
        for cxi in (-1, 1):
            parts.append(make_part(f"MansionColumn_{cx}_{cz}_{cxi}", (1.3, h * 0.85, 1.3), (cx + cxi * (w * 0.36), h * 0.42 + 0.6, cz + d / 2 + 1.5), color=MANSION_WHITE, material=256))
        parts.append(make_part(f"MansionBalcony_{cx}_{cz}", (w * 0.6, 0.6, 3), (cx, h * 0.7, cz + d / 2 + 1.5), color=accent_color, material=256))
        # Невеликий басейн перед будинком (з боку фасаду)
        parts.append(make_part(f"MansionPool_{cx}_{cz}", (0.6, 14, 14), (cx, 0.35, cz + d / 2 + 12), rot=(0, 0, 90), shape=2, color=POOL_WATER, material=304, transparency=0.25, can_collide=False))
        # Ворота при в'їзді (з боку дороги) + вивіска
        gate_children = label_children(label_text, bg_color=(0.08, 0.07, 0.02), stroke_color=(1.0, 0.85, 0.2))
        parts.append(make_part(f"MansionGateL_{cx}_{cz}", (1.2, 6, 1.2), (cx - 8, 3, cz + d / 2 + 24), color=MANSION_GATE, material=800))
        parts.append(make_part(f"MansionGateR_{cx}_{cz}", (1.2, 6, 1.2), (cx + 8, 3, cz + d / 2 + 24), color=MANSION_GATE, material=800, children_xml=gate_children))
        parts.append(make_part(f"MansionGateBar_{cx}_{cz}", (17, 0.4, 0.4), (cx, 5.2, cz + d / 2 + 24), color=GOLD_COLOR, material=800))
        # Пара декоративних кущів позаду будинку
        for txi in (-1, 1):
            parts.append(make_part(f"MansionHedge_{cx}_{cz}_{txi}", (2.5, 2.0, 2.5), (cx + txi * (w * 0.48), 1.0, cz - d / 2 - 1), shape=1, color=ZOO_GRASS, material=1280))
        return parts

    mansions = [
        (-90, -140, "🎮 GG Legend Villa", GOLD_COLOR),
        (90, -140, "👑 QueenClip Estate", RGB_PURPLE),
        (0, -290, "🌟 MrHype Grand Manor", HOVER_LED_BLUE),
    ]
    for mcx, mcz, mlabel, maccent in mansions:
        scale = 1.35 if mcz == -290 else 1.0
        city_parts.extend(build_mansion(mcx, mcz, mlabel, maccent, scale=scale))

    all_parts_xml = "\n".join(city_parts)

    # 3D Leaderboard Display Part with SurfaceGui
    leaderboard_display_xml = '''
		<Item class="Model" referent="RBX_StreamerCorner">
			<Properties>
				<string name="Name">StreamerCorner</string>
			</Properties>
			<Item class="Model" referent="RBX_LeaderboardBoard">
				<Properties>
					<string name="Name">LeaderboardBoard</string>
				</Properties>
				<Item class="Part" referent="RBX_LB_Display">
					<Properties>
						<string name="Name">Display</string>
						<bool name="Anchored">true</bool>
						<bool name="CanCollide">true</bool>
						<Vector3 name="size">
							<X>14.4</X><Y>10.4</Y><Z>0.2</Z>
						</Vector3>
						<CoordinateFrame name="CFrame">
							<X>-46</X><Y>9.5</Y><Z>141.8</Z>
							<R00>1</R00><R01>0</R01><R02>0</R02>
							<R10>0</R10><R11>1</R11><R12>0</R12>
							<R20>0</R20><R21>0</R21><R22>1</R22>
						</CoordinateFrame>
						<Color3uint8 name="Color3uint8">4280427045</Color3uint8>
						<token name="Material">256</token>
					</Properties>
					<Item class="SurfaceGui" referent="RBX_LB_SurfaceGui">
						<Properties>
							<string name="Name">LeaderboardGui</string>
							<token name="Face">5</token>
							<Vector2 name="CanvasSize">
								<X>800</X><Y>560</Y>
							</Vector2>
							<float name="LightInfluence">0</float>
							<bool name="AlwaysOnTop">false</bool>
						</Properties>
						<Item class="Frame" referent="RBX_LB_Header">
							<Properties>
								<string name="Name">Header</string>
								<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>0</YS><YO>70</YO></UDim2>
								<Color3 name="BackgroundColor3"><R>0.08</R><G>0.1</G><B>0.14</B></Color3>
								<float name="BackgroundTransparency">0</float>
							</Properties>
							<Item class="TextLabel" referent="RBX_LB_Title">
								<Properties>
									<string name="Name">Title</string>
									<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>0.6</YS><YO>0</YO></UDim2>
									<UDim2 name="Position"><XS>0</XS><XO>0</XO><YS>0</YS><YO>5</YO></UDim2>
									<float name="BackgroundTransparency">1</float>
									<string name="Text">🏆 TOP STREAMERS | WALL OF FAME</string>
									<Color3 name="TextColor3"><R>1</R><G>0.84</G><B>0</B></Color3>
									<token name="Font">17</token>
									<float name="TextSize">26</float>
								</Properties>
							</Item>
							<Item class="TextLabel" referent="RBX_LB_Sub">
								<Properties>
									<string name="Name">Subtitle</string>
									<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>0.35</YS><YO>0</YO></UDim2>
									<UDim2 name="Position"><XS>0</XS><XO>0</XO><YS>0.6</YS><YO>0</YO></UDim2>
									<float name="BackgroundTransparency">1</float>
									<string name="Text">⭐ Top Stream Channels Ranked by Subscribers</string>
									<Color3 name="TextColor3"><R>0.7</R><G>0.75</G><B>0.85</B></Color3>
									<token name="Font">16</token>
									<float name="TextSize">14</float>
								</Properties>
							</Item>
						</Item>
						<Item class="ScrollingFrame" referent="RBX_LB_Scroll">
							<Properties>
								<string name="Name">ScrollContainer</string>
								<UDim2 name="Size"><XS>1</XS><XO>-20</XO><YS>1</YS><YO>-85</YO></UDim2>
								<UDim2 name="Position"><XS>0</XS><XO>10</XO><YS>0</YS><YO>80</YO></UDim2>
								<float name="BackgroundTransparency">1</float>
								<token name="ScrollBarThickness">6</token>
							</Properties>
							<Item class="UIListLayout" referent="RBX_LB_Layout">
								<Properties>
									<token name="SortOrder">2</token>
									<UDim name="Padding"><S>0</S><O>8</O></UDim>
								</Properties>
							</Item>
						</Item>
					</Item>
				</Item>
			</Item>
		</Item>'''

    # SpawnLocation INSIDE Streamer Room, facing the gaming desk (-Z)
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
					<X>0</X><Y>1.8</Y><Z>-62</Z>
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
			{hoverboard_model_xml}
		</Item>
		{leaderboard_display_xml}
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
			<Item class="ModuleScript" referent="RBX_StreamConfig">
				<Properties>
					<string name="Name">StreamConfig</string>
					<ProtectedString name="Source"><![CDATA[{stream_config_src}]]></ProtectedString>
				</Properties>
			</Item>
			<Item class="ModuleScript" referent="RBX_StreamEventsConfig">
				<Properties>
					<string name="Name">StreamEventsConfig</string>
					<ProtectedString name="Source"><![CDATA[{stream_events_src}]]></ProtectedString>
				</Properties>
			</Item>
			<Item class="ModuleScript" referent="RBX_ShopConfig">
				<Properties>
					<string name="Name">ShopConfig</string>
					<ProtectedString name="Source"><![CDATA[{shop_config_src}]]></ProtectedString>
				</Properties>
			</Item>
			<Item class="ModuleScript" referent="RBX_EnvironmentConfig">
				<Properties>
					<string name="Name">EnvironmentConfig</string>
					<ProtectedString name="Source"><![CDATA[{environment_config_src}]]></ProtectedString>
				</Properties>
			</Item>
		</Item>
		<Item class="Folder" referent="RBX_RemotesFolder">
			<Properties>
				<string name="Name">Remotes</string>
			</Properties>
			<Item class="RemoteEvent" referent="RBX_ToggleStream">
				<Properties>
					<string name="Name">ToggleStream</string>
				</Properties>
			</Item>
			<Item class="RemoteEvent" referent="RBX_StreamStateChanged">
				<Properties>
					<string name="Name">StreamStateChanged</string>
				</Properties>
			</Item>
			<Item class="RemoteEvent" referent="RBX_SetChannelName">
				<Properties>
					<string name="Name">SetChannelName</string>
				</Properties>
			</Item>
			<Item class="RemoteEvent" referent="RBX_BuyShopItem">
				<Properties>
					<string name="Name">BuyShopItem</string>
				</Properties>
			</Item>
			<Item class="RemoteEvent" referent="RBX_ShopItemPurchased">
				<Properties>
					<string name="Name">ShopItemPurchased</string>
				</Properties>
			</Item>
			<Item class="RemoteEvent" referent="RBX_StreamPromptEvent">
				<Properties>
					<string name="Name">StreamPromptEvent</string>
				</Properties>
			</Item>
			<Item class="RemoteEvent" referent="RBX_SubmitStreamChoice">
				<Properties>
					<string name="Name">SubmitStreamChoice</string>
				</Properties>
			</Item>
			<Item class="RemoteEvent" referent="RBX_StreamChoiceResult">
				<Properties>
					<string name="Name">StreamChoiceResult</string>
				</Properties>
			</Item>
		</Item>
		<Item class="Folder" referent="RBX_EventStateFolder">
			<Properties>
				<string name="Name">EventState</string>
			</Properties>
			<Item class="BoolValue" referent="RBX_IsBoostActive">
				<Properties>
					<string name="Name">IsBoostActive</string>
					<bool name="Value">false</bool>
				</Properties>
			</Item>
			<Item class="IntValue" referent="RBX_RemainingSeconds">
				<Properties>
					<string name="Name">RemainingSeconds</string>
					<int name="Value">3000</int>
				</Properties>
			</Item>
		</Item>
	</Item>
	<Item class="ServerScriptService" referent="RBX_ServerScriptService">
		<Properties>
			<string name="Name">ServerScriptService</string>
		</Properties>
		<Item class="Script" referent="RBX_Leaderstats">
			<Properties>
				<string name="Name">Leaderstats</string>
				<ProtectedString name="Source"><![CDATA[{leaderstats_src}]]></ProtectedString>
			</Properties>
		</Item>
		<Item class="Script" referent="RBX_StreamManager">
			<Properties>
				<string name="Name">StreamManager</string>
				<ProtectedString name="Source"><![CDATA[{stream_manager_src}]]></ProtectedString>
			</Properties>
		</Item>
		<Item class="Script" referent="RBX_ShopManager">
			<Properties>
				<string name="Name">ShopManager</string>
				<ProtectedString name="Source"><![CDATA[{shop_manager_src}]]></ProtectedString>
			</Properties>
		</Item>
		<Item class="Script" referent="RBX_EventManager">
			<Properties>
				<string name="Name">EventManager</string>
				<ProtectedString name="Source"><![CDATA[{event_manager_src}]]></ProtectedString>
			</Properties>
		</Item>
		<Item class="Script" referent="RBX_LeaderboardManager">
			<Properties>
				<string name="Name">LeaderboardManager</string>
				<ProtectedString name="Source"><![CDATA[{leaderboard_manager_src}]]></ProtectedString>
			</Properties>
		</Item>
		<Item class="Script" referent="RBX_VehicleManager">
			<Properties>
				<string name="Name">VehicleManager</string>
				<ProtectedString name="Source"><![CDATA[{vehicle_manager_src}]]></ProtectedString>
			</Properties>
		</Item>
		<Item class="Script" referent="RBX_EnvironmentManager">
			<Properties>
				<string name="Name">EnvironmentManager</string>
				<ProtectedString name="Source"><![CDATA[{environment_manager_src}]]></ProtectedString>
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
			<Item class="LocalScript" referent="RBX_StreamGui">
				<Properties>
					<string name="Name">StreamGui</string>
					<ProtectedString name="Source"><![CDATA[{stream_gui_src}]]></ProtectedString>
				</Properties>
			</Item>
			<Item class="LocalScript" referent="RBX_StreamController">
				<Properties>
					<string name="Name">StreamController</string>
					<ProtectedString name="Source"><![CDATA[{stream_controller_src}]]></ProtectedString>
				</Properties>
			</Item>
			<Item class="LocalScript" referent="RBX_PlatformSelectGui">
				<Properties>
					<string name="Name">PlatformSelectGui</string>
					<ProtectedString name="Source"><![CDATA[{platform_select_gui_src}]]></ProtectedString>
				</Properties>
			</Item>
			<Item class="LocalScript" referent="RBX_StreamEventGui">
				<Properties>
					<string name="Name">StreamEventGui</string>
					<ProtectedString name="Source"><![CDATA[{stream_event_gui_src}]]></ProtectedString>
				</Properties>
			</Item>
			<Item class="LocalScript" referent="RBX_ShopGui">
				<Properties>
					<string name="Name">ShopGui</string>
					<ProtectedString name="Source"><![CDATA[{shop_gui_src}]]></ProtectedString>
				</Properties>
			</Item>
			<Item class="LocalScript" referent="RBX_VehicleGui">
				<Properties>
					<string name="Name">VehicleGui</string>
					<ProtectedString name="Source"><![CDATA[{vehicle_gui_src}]]></ProtectedString>
				</Properties>
			</Item>
			<Item class="LocalScript" referent="RBX_CityWaypoints">
				<Properties>
					<string name="Name">CityWaypoints</string>
					<ProtectedString name="Source"><![CDATA[{city_waypoints_src}]]></ProtectedString>
				</Properties>
			</Item>
			<Item class="LocalScript" referent="RBX_RobuxStoreGui">
				<Properties>
					<string name="Name">RobuxStoreGui</string>
					<ProtectedString name="Source"><![CDATA[{robux_store_gui_src}]]></ProtectedString>
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


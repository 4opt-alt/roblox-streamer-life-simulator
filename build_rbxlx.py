import os
import math

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

    hoverboard_parts.append(make_part("HoverboardBody", (1.6, 0.3, 4.4), (14, 2.0, -42), color=HOVER_NAVY_DARK, material=256, anchored=True, can_collide=False, children_xml=hoverboard_children))
    hoverboard_parts.append(make_part("VehicleSeat", (1.2, 0.2, 1.2), (14, 2.3, -42), color=CHAIR_BLACK, material=816, anchored=True, can_collide=False, transparency=0.85, is_seat="vehicle"))

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
    hoverboard_parts.append(make_part("WheelFront", (0.4, 1.0, 1.0), (14, 1.4, -44.0), color=HOVER_WHEEL_BLACK, material=256, anchored=True, can_collide=True, shape=2))
    hoverboard_parts.append(make_part("WheelBack", (0.4, 1.0, 1.0), (14, 1.4, -40.0), color=HOVER_WHEEL_BLACK, material=256, anchored=True, can_collide=True, shape=2))

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

    # Also copy to Desktop
    desktop_path = r"C:\Users\lyutu\Desktop\StreamerGame.rbxlx"
    with open(desktop_path, "w", encoding="utf-8") as f:
        f.write(rbxlx_content)
    print(f"Copied to Desktop: {desktop_path} ({os.path.getsize(desktop_path)} bytes)")

    # Auto-sync to Git & GitHub
    if auto_push:
        try:
            import subprocess, time
            git_cmd = r"C:\Users\lyutu\.tools\git\cmd\git.exe"
            if os.path.exists(git_cmd):
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


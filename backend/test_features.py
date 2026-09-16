import json
import time
import urllib.request
import urllib.error

BASE_URL = "http://localhost:5000/api"

def make_request(path, method="GET", data=None, token=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    req_data = None
    if data is not None:
      req_data = json.dumps(data).encode("utf-8")
        
    req = urllib.request.Request(url, data=req_data, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req) as res:
            res_body = res.read().decode("utf-8")
            return json.loads(res_body) if res_body else {}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        print(f"HTTP Error {e.code} on {method} {path}: {err_body}")
        raise e

def test_flow():
    print("--- Starting End-to-End Feature Verification ---")

    # 1. Student Login
    print("\n1. Logging in as student...")
    student_auth = make_request("/auth/login", "POST", {"email": "student@test.com", "password": "student123"})
    student_token = student_auth["access_token"]
    print("   [OK] Student token obtained.")

    # 2. Register FCM Token
    print("\n2. Registering Student FCM Token...")
    fcm_res = make_request("/auth/fcm-token", "POST", {"fcm_token": "test_token_student_456"}, student_token)
    print("   [OK] Response:", fcm_res)

    # 3. Create Support Chat Room
    print("\n3. Creating support chat room...")
    room_res = make_request("/chat/rooms", "POST", {}, student_token)
    room = room_res["room"]
    room_id = room["id"]
    print(f"   [OK] Room created. ID: {room_id}, Status: {room['status']}")

    # 4. Admin Login
    print("\n4. Logging in as admin...")
    admin_auth = make_request("/auth/admin/login", "POST", {"username": "admin", "password": "admin123"})
    admin_token = admin_auth["access_token"]
    print("   [OK] Admin token obtained.")

    # 5. List Active Chat Rooms as Admin
    print("\n5. Listing active chat rooms as admin...")
    active_rooms = make_request("/chat/rooms/active", "GET", token=admin_token)
    print(f"   [OK] Active rooms: {len(active_rooms['rooms'])}")
    assert any(r["id"] == room_id for r in active_rooms["rooms"]), "Created room not listed!"

    # 6. Retrieve Messages
    print("\n6. Fetching chat messages...")
    msgs = make_request(f"/chat/rooms/{room_id}/messages", "GET", token=student_token)
    print(f"   [OK] Message count: {len(msgs['messages'])}")
    for m in msgs["messages"]:
        print(f"      - {m['sender_role']}: {m['message']}")

    # 7. Create a mock order to test KDS
    print("\n7. Simulating Order and checking KDS...")
    # To place an order, we first need to add items to cart.
    # Let's add Idli (Counter 1) and Chicken Biryani (Counter 2) to cart.
    print("   Adding Idli (Counter 1) and Chicken Biryani (Counter 2) to cart...")
    # Let's fetch menu items first
    menu = make_request("/menu/food-items", "GET", token=student_token)
    idli = next(item for item in menu["items"] if "Idli" in item["name"])
    biryani = next(item for item in menu["items"] if "Biryani" in item["name"])
    
    # Empty cart first (failsafe)
    try: make_request("/cart", "DELETE", token=student_token)
    except: pass
    
    make_request("/cart/items", "POST", {"food_item_id": idli["id"], "quantity": 2}, student_token)
    make_request("/cart/items", "POST", {"food_item_id": biryani["id"], "quantity": 1}, student_token)
    
    # Checkout
    order_res = make_request("/orders", "POST", {"pickup_time": "12:30 PM", "notes": "KDS Test", "payment_method": "cash"}, student_token)
    order_id = order_res["order"]["order_id"]
    order_db_id = order_res["order"]["id"]
    print(f"   [OK] Mock order placed. Code: {order_id}, DB ID: {order_db_id}")

    # 8. Check KDS for Counter 1 and Counter 2
    print("\n8. Checking KDS filters...")
    c1_orders = make_request("/admin/kds/orders?counter=1", "GET", token=admin_token)
    c2_orders = make_request("/admin/kds/orders?counter=2", "GET", token=admin_token)
    
    c1_matching = [o for o in c1_orders["orders"] if o["order_id"] == order_id]
    c2_matching = [o for o in c2_orders["orders"] if o["order_id"] == order_id]
    
    print(f"   Counter 1 match found: {len(c1_matching) > 0}")
    print(f"   Counter 2 match found: {len(c2_matching) > 0}")
    
    idli_order_item_id = c1_matching[0]["items"][0]["id"]
    biryani_order_item_id = c2_matching[0]["items"][0]["id"]

    # 9. Mark Counter 1 Item Prepared
    print(f"\n9. Marking Counter 1 Item (ID: {idli_order_item_id}) as prepared...")
    item_res = make_request(f"/admin/kds/items/{idli_order_item_id}/prepare", "POST", token=admin_token)
    print(f"   [OK] Item marked prepared. Parent Order status: {item_res['order_status']}")
    assert item_res["order_status"] == "preparing", "Order should be in preparing status!"

    # 10. Mark Counter 2 Item Prepared
    print(f"\n10. Marking Counter 2 Item (ID: {biryani_order_item_id}) as prepared...")
    item_res2 = make_request(f"/admin/kds/items/{biryani_order_item_id}/prepare", "POST", token=admin_token)
    print(f"   [OK] Item marked prepared. Parent Order status: {item_res2['order_status']}")
    assert item_res2["order_status"] == "ready", "Order should now be ready since all items are prepared!"

    # 11. Close Chat Room
    print("\n11. Closing support chat room...")
    close_res = make_request(f"/chat/rooms/{room_id}/close", "POST", token=student_token)
    print(f"   [OK] Room status now: {close_res['room']['status']}")

    print("\n--- E2E Feature Verification Completed Successfully! ---")

if __name__ == "__main__":
    test_flow()

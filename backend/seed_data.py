"""Seed database with sample data for testing."""
from app import create_app
from app.extensions import db
from app.models.user import User
from app.models.admin import Admin
from app.models.category import Category
from app.models.food_item import FoodItem
from app.models.inventory import Inventory
from app.utils.auth_helpers import hash_password


def seed():
    """Seed the database with sample data."""
    app = create_app()

    with app.app_context():
        print('Seeding database...')

        # ─── Default Admin ────────────────────────────
        if not Admin.query.filter_by(username='admin').first():
            admin = Admin(
                username='admin',
                full_name='Canteen Admin',
                email='admin@smartcanteen.com',
                password_hash=hash_password('admin123'),
                role='admin',
            )
            db.session.add(admin)
            print('  [OK] Admin created (admin / admin123)')

        # ─── Categories ───────────────────────────────
        categories_data = [
            {'name': 'Breakfast', 'description': 'Start your day right', 'display_order': 1},
            {'name': 'Lunch', 'description': 'Filling meals for midday', 'display_order': 2},
            {'name': 'Snacks', 'description': 'Quick bites anytime', 'display_order': 3},
            {'name': 'Juice & Beverages', 'description': 'Refreshing drinks', 'display_order': 4},
            {'name': 'Desserts', 'description': 'Sweet treats', 'display_order': 5},
        ]

        for cat_data in categories_data:
            if not Category.query.filter_by(name=cat_data['name']).first():
                db.session.add(Category(**cat_data))
        db.session.flush()
        print('  [OK] Categories created')

        # ─── Food Items ───────────────────────────────
        categories = {c.name: c.id for c in Category.query.all()}

        food_items = [
            # Breakfast
            {'name': 'Idli (2 pcs)', 'description': 'Soft steamed rice cakes served with sambar and chutney', 'price': 30, 'category_id': categories.get('Breakfast'), 'quantity': 50, 'preparation_time': 5, 'is_veg': True, 'is_special': True, 'total_orders': 120, 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Dosa', 'description': 'Crispy golden crepe made from rice and lentil batter', 'price': 40, 'category_id': categories.get('Breakfast'), 'quantity': 40, 'preparation_time': 8, 'is_veg': True, 'total_orders': 95, 'image': 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Masala Dosa', 'description': 'Crispy dosa filled with spiced potato masala', 'price': 50, 'category_id': categories.get('Breakfast'), 'quantity': 35, 'preparation_time': 10, 'is_veg': True, 'is_special': True, 'total_orders': 110, 'image': 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Poori (3 pcs)', 'description': 'Deep fried puffy bread with potato curry', 'price': 45, 'category_id': categories.get('Breakfast'), 'quantity': 30, 'preparation_time': 8, 'is_veg': True, 'total_orders': 70, 'image': 'https://images.unsplash.com/photo-1541014741259-df5290dbf82b?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Upma', 'description': 'Savory semolina porridge with vegetables', 'price': 25, 'category_id': categories.get('Breakfast'), 'quantity': 40, 'preparation_time': 5, 'is_veg': True, 'total_orders': 55, 'image': 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Pongal', 'description': 'Creamy rice and lentil dish with pepper and cumin', 'price': 35, 'category_id': categories.get('Breakfast'), 'quantity': 30, 'preparation_time': 5, 'is_veg': True, 'total_orders': 65, 'image': 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Egg Dosa', 'description': 'Dosa topped with a perfectly spread egg', 'price': 45, 'category_id': categories.get('Breakfast'), 'quantity': 25, 'preparation_time': 8, 'is_veg': False, 'total_orders': 40, 'image': 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=500&auto=format&fit=crop&q=60'},
            # Lunch
            {'name': 'Meals (Veg)', 'description': 'Full South Indian meals with rice, sambar, rasam, kootu, poriyal, curd', 'price': 70, 'category_id': categories.get('Lunch'), 'quantity': 100, 'preparation_time': 5, 'is_veg': True, 'is_special': True, 'total_orders': 200, 'image': 'https://images.unsplash.com/photo-1610192244261-3f33de3f55e4?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Chicken Biryani', 'description': 'Fragrant basmati rice layered with spiced chicken', 'price': 120, 'category_id': categories.get('Lunch'), 'quantity': 60, 'preparation_time': 10, 'is_veg': False, 'is_special': True, 'total_orders': 180, 'image': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Veg Biryani', 'description': 'Aromatic rice with mixed vegetables and spices', 'price': 80, 'category_id': categories.get('Lunch'), 'quantity': 50, 'preparation_time': 10, 'is_veg': True, 'total_orders': 85, 'image': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Chapati (3 pcs)', 'description': 'Soft wheat flatbread with dal and curry', 'price': 50, 'category_id': categories.get('Lunch'), 'quantity': 40, 'preparation_time': 8, 'is_veg': True, 'total_orders': 60, 'image': 'https://images.unsplash.com/photo-1627308595229-7830a5c91f9f?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Egg Rice', 'description': 'Fried rice with scrambled eggs and vegetables', 'price': 60, 'category_id': categories.get('Lunch'), 'quantity': 35, 'preparation_time': 8, 'is_veg': False, 'total_orders': 45, 'image': 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Lemon Rice', 'description': 'Tangy turmeric rice with peanuts and curry leaves', 'price': 40, 'category_id': categories.get('Lunch'), 'quantity': 45, 'preparation_time': 5, 'is_veg': True, 'total_orders': 55, 'image': 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500&auto=format&fit=crop&q=60'},
            # Snacks
            {'name': 'Samosa (2 pcs)', 'description': 'Crispy pastry filled with spiced potato and peas', 'price': 20, 'category_id': categories.get('Snacks'), 'quantity': 80, 'preparation_time': 3, 'is_veg': True, 'is_special': True, 'total_orders': 150, 'image': 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Vada (2 pcs)', 'description': 'Crispy lentil fritters served with coconut chutney', 'price': 25, 'category_id': categories.get('Snacks'), 'quantity': 60, 'preparation_time': 5, 'is_veg': True, 'total_orders': 90, 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Bajji / Pakoda', 'description': 'Mixed vegetable fritters with gram flour batter', 'price': 25, 'category_id': categories.get('Snacks'), 'quantity': 50, 'preparation_time': 5, 'is_veg': True, 'total_orders': 75, 'image': 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Paneer Roll', 'description': 'Soft roti wrap with spiced paneer filling', 'price': 50, 'category_id': categories.get('Snacks'), 'quantity': 30, 'preparation_time': 8, 'is_veg': True, 'total_orders': 40, 'image': 'https://images.unsplash.com/photo-1626132647523-66f5bf380027?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Egg Puff', 'description': 'Flaky puff pastry with boiled egg filling', 'price': 20, 'category_id': categories.get('Snacks'), 'quantity': 40, 'preparation_time': 3, 'is_veg': False, 'total_orders': 65, 'image': 'https://images.unsplash.com/photo-1558985250-27a406d64cb3?w=500&auto=format&fit=crop&q=60'},
            {'name': 'French Fries', 'description': 'Crispy golden potato fries with ketchup', 'price': 40, 'category_id': categories.get('Snacks'), 'quantity': 50, 'preparation_time': 8, 'is_veg': True, 'total_orders': 80, 'image': 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&auto=format&fit=crop&q=60'},
            # Juice & Beverages
            {'name': 'Fresh Orange Juice', 'description': 'Freshly squeezed orange juice', 'price': 40, 'category_id': categories.get('Juice & Beverages'), 'quantity': 30, 'preparation_time': 5, 'is_veg': True, 'total_orders': 70, 'image': 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Mango Lassi', 'description': 'Creamy yogurt smoothie with mango pulp', 'price': 45, 'category_id': categories.get('Juice & Beverages'), 'quantity': 25, 'preparation_time': 5, 'is_veg': True, 'is_special': True, 'total_orders': 60, 'image': 'https://images.unsplash.com/photo-1541658016709-82535e94bc69?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Coffee', 'description': 'Hot filter coffee with frothed milk', 'price': 15, 'category_id': categories.get('Juice & Beverages'), 'quantity': 100, 'preparation_time': 3, 'is_veg': True, 'total_orders': 200, 'image': 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Tea', 'description': 'Traditional masala chai with ginger', 'price': 10, 'category_id': categories.get('Juice & Beverages'), 'quantity': 100, 'preparation_time': 3, 'is_veg': True, 'total_orders': 180, 'image': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Buttermilk', 'description': 'Spiced chilled buttermilk with curry leaves', 'price': 15, 'category_id': categories.get('Juice & Beverages'), 'quantity': 50, 'preparation_time': 3, 'is_veg': True, 'total_orders': 45, 'image': 'https://images.unsplash.com/photo-1541658016709-82535e94bc69?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Watermelon Juice', 'description': 'Fresh watermelon juice with a hint of mint', 'price': 35, 'category_id': categories.get('Juice & Beverages'), 'quantity': 20, 'preparation_time': 5, 'is_veg': True, 'total_orders': 35, 'image': 'https://images.unsplash.com/photo-1587132137056-bfbf0166836e?w=500&auto=format&fit=crop&q=60'},
            # Desserts
            {'name': 'Gulab Jamun (2 pcs)', 'description': 'Soft milk dumplings soaked in rose-scented sugar syrup', 'price': 30, 'category_id': categories.get('Desserts'), 'quantity': 40, 'preparation_time': 3, 'is_veg': True, 'total_orders': 55, 'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Kesari / Sheera', 'description': 'Sweet semolina pudding with saffron and cashews', 'price': 25, 'category_id': categories.get('Desserts'), 'quantity': 35, 'preparation_time': 3, 'is_veg': True, 'total_orders': 40, 'image': 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500&auto=format&fit=crop&q=60'},
            {'name': 'Ice Cream Cup', 'description': 'Creamy vanilla ice cream cup', 'price': 30, 'category_id': categories.get('Desserts'), 'quantity': 50, 'preparation_time': 1, 'is_veg': True, 'total_orders': 60, 'image': 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=500&auto=format&fit=crop&q=60'},
        ]

        for item_data in food_items:
            if not FoodItem.query.filter_by(name=item_data['name']).first():
                # Assign counters dynamically based on categories
                cat_id = item_data.get('category_id')
                if cat_id == categories.get('Breakfast'):
                    item_data['counter_number'] = 1
                elif cat_id == categories.get('Lunch'):
                    item_data['counter_number'] = 2
                elif cat_id == categories.get('Juice & Beverages'):
                    item_data['counter_number'] = 3
                elif cat_id == categories.get('Desserts'):
                    item_data['counter_number'] = 3
                else:  # Snacks
                    item_data['counter_number'] = 1
                db.session.add(FoodItem(**item_data))
        print(f'  [OK] {len(food_items)} food items created')

        # ─── Inventory Items ──────────────────────────
        inventory_items = [
            {'item_name': 'Rice', 'quantity': 50, 'unit': 'kg', 'reorder_level': 10, 'cost_per_unit': 45},
            {'item_name': 'Wheat Flour', 'quantity': 25, 'unit': 'kg', 'reorder_level': 5, 'cost_per_unit': 35},
            {'item_name': 'Oil', 'quantity': 20, 'unit': 'liters', 'reorder_level': 5, 'cost_per_unit': 140},
            {'item_name': 'Sugar', 'quantity': 15, 'unit': 'kg', 'reorder_level': 3, 'cost_per_unit': 42},
            {'item_name': 'Milk', 'quantity': 30, 'unit': 'liters', 'reorder_level': 10, 'cost_per_unit': 55},
            {'item_name': 'Eggs', 'quantity': 200, 'unit': 'pieces', 'reorder_level': 50, 'cost_per_unit': 7},
            {'item_name': 'Chicken', 'quantity': 10, 'unit': 'kg', 'reorder_level': 3, 'cost_per_unit': 250},
            {'item_name': 'Urad Dal', 'quantity': 10, 'unit': 'kg', 'reorder_level': 3, 'cost_per_unit': 120},
            {'item_name': 'Potatoes', 'quantity': 20, 'unit': 'kg', 'reorder_level': 5, 'cost_per_unit': 30},
            {'item_name': 'Onions', 'quantity': 15, 'unit': 'kg', 'reorder_level': 5, 'cost_per_unit': 35},
            {'item_name': 'Coffee Powder', 'quantity': 5, 'unit': 'kg', 'reorder_level': 1, 'cost_per_unit': 400},
            {'item_name': 'Tea Powder', 'quantity': 3, 'unit': 'kg', 'reorder_level': 1, 'cost_per_unit': 350},
            {'item_name': 'Bread', 'quantity': 20, 'unit': 'packets', 'reorder_level': 10, 'cost_per_unit': 40},
        ]

        for inv_data in inventory_items:
            if not Inventory.query.filter_by(item_name=inv_data['item_name']).first():
                db.session.add(Inventory(**inv_data))
        print(f'  [OK] {len(inventory_items)} inventory items created')

        # ─── Sample Student ───────────────────────────
        if not User.query.filter_by(email='student@test.com').first():
            student = User(
                full_name='Test Student',
                register_number='REG001',
                department='Computer Science',
                year=3,
                mobile_number='9876543210',
                email='student@test.com',
                password_hash=hash_password('student123'),
                is_verified=True,
            )
            db.session.add(student)
            print('  [OK] Test student created (student@test.com / student123)')

        db.session.commit()
        print('\nDatabase seeded successfully!')
        print('-' * 40)
        print('  Admin Login:   admin / admin123')
        print('  Student Login: student@test.com / student123')
        print('-' * 40)


if __name__ == '__main__':
    seed()

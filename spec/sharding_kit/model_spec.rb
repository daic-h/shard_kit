require "spec_helper"

RSpec.describe ShardingKit::Model, clean_all: true do
  describe ".on_db" do
    it "should allow to pass a string as the shard name to a AR subclass" do
      user = User.on_db(:shard_1).create!(name: "Yuki")

      expect(User.on_db(:shard_1).where(name: "Yuki").take).to eq(user)
    end

    it "should allow to pass a string as the shard name to a block" do
      user = User.on_db(:shard_1) do
        User.create!(name: "Yuki")
      end

      expect(User.on_db(:shard_1).where(name: "Yuki").take).to eq(user)
    end

    it "should allow selecting the shards on scope" do
      User.on_db(:shard_1).create!(name: "Yuki")

      expect(User.on_db(:shard_1).count).to eq(1)
      expect(User.count).to eq(0)
    end

    it "should allow selecting the shard on_db #new" do
      u = User.on_db(:shard_1).new
      u.name = "Yuki"
      u.save

      expect(User.on_db(:master).count).to eq(0)
      expect(User.on_db(:shard_1).count).to eq(1)

      u1 = User.new
      u1.name = "Megu"
      u1.save

      u2 = User.on_db(:shard_1).new
      u2.name = "Yume"
      u2.save

      expect(User.on_db(:shard_1).all).to eq([u, u2])
      expect(User.all).to eq([u1])
    end

    describe "multiple calls to the same scope" do
      it "works with nil response" do
        scope = User.on_db(:shard_1)

        expect(scope.count).to eq(0)
        expect(scope.first).to be_nil
      end

      it "works with non-nil response" do
        user = User.on_db(:shard_1).create!(name: "Yuki")
        scope = User.on_db(:shard_1)

        expect(scope.count).to eq(1)
        expect(scope.first).to eq(user)
      end
    end

    it "should select the correct shard" do
      User.on_db(:shard_1)
      User.create!(name: "Yuki")

      expect(User.count).to eq(1)
    end

    it "should ensure that the connection will be cleaned" do
      expect(ActiveRecord::Base.connection_name).to eq(:master)
      expect do
        ActiveRecord::Base.on_db(:shard_1) do
          raise "Some Exception"
        end
      end.to raise_error(RuntimeError)

      expect(ActiveRecord::Base.connection_name).to eq(:master)
    end

    it "should allow creating more than one user" do
      User.on_db(:shard_1).create([{ name: "Shard1 User 1" }, { name: "Shard1 User 2" }])
      User.create!(name: "User 3")

      expect(User.on_db(:shard_1).where(name: "Shard1 User 1").take).not_to be_nil
      expect(User.on_db(:shard_1).where(name: "Shard1 User 2").take).not_to be_nil
      expect(User.on_db(:master).where(name: "User 3").take).not_to be_nil
    end

    it "should clean #connection_name from proxy when on_db execute" do
      User.on_db(:shard_1).connection.execute("select * from users limit 1;")

      expect(User.connection_name).to eq(:master)
    end

    it "should allow scoping dynamically" do
      User.on_db(:shard_1).on_db(:master).on_db(:shard_1).create!(name: "oi")

      expect(User.on_db(:shard_1).count).to eq(1)
      expect(User.on_db(:shard_1).on_db(:master).count).to eq(0)
      expect(User.on_db(:master).on_db(:shard_1).count).to eq(1)
    end

    it "should allow find inside blocks" do
      user = User.on_db(:shard_2).create!(name: "User")

      User.on_db(:shard_2) do
        expect(User.first).to eq(user)
      end

      expect(User.on_db(:shard_2).where(name: "User").take).to eq(user)
    end

    it "should work with named scopes" do
      u = User.on_db(:shard_1).create!(name: "Admin")

      expect(User.admin.on_db(:shard_1).take).to eq(u)
      expect(User.on_db(:shard_1).admin.take).to eq(u)

      User.on_db(:shard_1) do
        expect(User.admin.take).to eq(u)
      end

      expect(User.admin.take).to be_nil
    end
  end

  describe ".clear_active_connections!" do
    it "should not leak connection" do
      User.on_db(:shard_1).create(name: "User")

      expect { ActiveRecord::Base.clear_active_connections! }
        .to change { User.on_db(:shard_1).connection_pool.active_connection? }

      expect(User.on_db(:shard_1).connection_pool.active_connection?).to be_falsey
    end
  end

  describe "#connection_name" do
    it "should store the attribute when you create or find an object" do
      user = User.on_db(:shard_1).create!(name: "User1")
      expect(user.connection_name).to eq(:shard_1)

      User.on_db(:shard_2).create!(name: "User2")
      user = User.on_db(:shard_2).where(name: "User2").take
      expect(user.connection_name).to eq(:shard_2)
    end

    it "should store the attribute when you find multiple instances" do
      5.times { User.on_db(:shard_1).create!(name: "User") }

      User.on_db(:shard_1).all.each do |u|
        expect(u.connection_name).to eq(:shard_1)
      end
    end

    it "should works when you find, and after that, alter that object" do
      shard_user = User.on_db(:shard_1).create!(name: "Shard")
      User.on_db(:master).create!(name: "Master")
      shard_user.name = "Shard1"
      shard_user.save

      expect(User.on_db(:master).first.name).to eq("Master")
      expect(User.on_db(:shard_1).first.name).to eq("Shard1")
    end
  end

  describe "#reload" do
    let!(:user) do
      User.on_db(:shard_1).create!(name: "User")
    end

    it "should work for the reload method" do
      User.on_db(:shard_1).where(id: user.id).update_all(name: "User2")

      expect(user.reload.name).to eq("User2")
    end

    it "should work passing some arguments to reload method" do
      User.on_db(:shard_1).where(id: user.id).update_all(name: "User2")

      expect(user.reload(lock: true).name).to eq("User2")
    end
  end

  describe "#touch" do
    let!(:user) do
      User.on_db(:shard_1).create!(name: "User")
    end

    it "updates updated_at by default" do
      User.on_db(:shard_1).where(id: user.id).update_all(updated_at: Time.now - 3.months)
      user.touch

      expect(user.reload.updated_at.in_time_zone("GMT").to_date).to eq(Time.now.in_time_zone("GMT").to_date)
    end

    it "updates passed in attribute name" do
      User.on_db(:shard_1).where(id: user.id).update_all(created_at: Time.now - 3.months)
      user.touch(:created_at)

      expect(user.reload.created_at.in_time_zone("GMT").to_date).to eq(Time.now.in_time_zone("GMT").to_date)
    end
  end

  describe "#association" do
    context "when you have a 1 x 1 relationship" do
      before(:each) do
        @supplier_shard1 = Supplier.on_db(:shard_1).create!(name: "Supplier Shard1")
        @supplier_shard2 = Supplier.on_db(:shard_2).create!(name: "Supplier Shard2")
        @account_shard1 = Account.on_db(:shard_1).create!(name: "Account Shard1", supplier: @supplier_shard1)
        @account_shard2 = Account.on_db(:shard_2).create!(name: "Account Shard2", supplier: @supplier_shard2)
      end

      it "should find the models" do
        expect(@supplier_shard1.account).to eq(@account_shard1)
        expect(@supplier_shard2.account).to eq(@account_shard2)
      end

      it "should read correctly the relationed model" do
        new_supplier_shard1 = Supplier.on_db(:shard_1).create!(name: "New Supplier Shard1")
        @account_shard1.supplier = new_supplier_shard1
        @account_shard1.save
        @account_shard1.reload

        expect(@account_shard1.supplier_id).to eq(new_supplier_shard1.id)
        expect(@account_shard1.supplier).to eq(new_supplier_shard1)

        new_supplier_shard1.save
        new_supplier_shard1.reload

        expect(new_supplier_shard1.account).to eq(@account_shard1)
      end

      it "should work when on_db #build_account" do
        supplier_shard1 = Supplier.on_db(:shard_1).create!(name: "Supplier Shard1")
        account_shard1 = supplier_shard1.build_account(name: "Account Shard1")
        supplier_shard1.save

        expect(supplier_shard1.account).to eq(account_shard1)
        expect(account_shard1.persisted?).to be_truthy
        expect(account_shard1.supplier_id).to eq(supplier_shard1.id)
        expect(account_shard1.supplier).to eq(supplier_shard1)
      end

      it "should work when on_db #create_account" do
        supplier_shard1 = Supplier.on_db(:shard_1).create!(name: "Supplier Shard1")
        account_shard1 = supplier_shard1.create_account(name: "Account Shard1")

        expect(supplier_shard1.account).to eq(account_shard1)
        expect(account_shard1.supplier_id).to eq(supplier_shard1.id)
        expect(account_shard1.supplier).to eq(supplier_shard1)
      end

      it "should include models" do
        supplier_shard1 = Supplier.on_db(:shard_1).create!(name: "Supplier Shard1")
        supplier_shard1.create_account(name: "Account Shard1")

        expect(Supplier.on_db(:shard_1).includes(:account).find(supplier_shard1.id)).to eq(supplier_shard1)
      end
    end

    context "when you have a 1 x N relationship" do
      before(:each) do
        @customer_s1 = Customer.on_db(:shard_1).create!(name: "Customer Shard1")
        @customer_s2 = Customer.on_db(:shard_2).create!(name: "Customer Shard2")
        @order_s1 = Order.on_db(:shard_1).create!(name: "Order Shard1", customer: @customer_s1)
        @order_s2 = Order.on_db(:shard_2).create!(name: "Order Shard2", customer: @customer_s2)

        @customer_s1 = Customer.on_db(:shard_1).where(name: "Customer Shard1").take
        Customer.on_db(:shard_1).create!(name: "Test")
      end

      it "should find all models in the specified shard" do
        expect(@customer_s1.order_ids).to eq([@order_s1.id])
        expect(@customer_s1.orders).to eq([@order_s1])

        expect(@customer_s1.orders.first).to eq(@order_s1)
        expect(@customer_s1.orders.last).to eq(@order_s1)
      end

      it "should finds the customer that the order belongs" do
        expect(@order_s1.customer).to eq(@customer_s1)
      end

      it "should update the attribute for the order" do
        customer = Customer.on_db(:shard_1).create!(name: "new Customer")
        @order_s1.customer = customer

        expect(@order_s1.customer).to eq(customer)

        @order_s1.save
        @order_s1.reload

        expect(@order_s1.customer_id).to eq(customer.id)
        expect(@order_s1.customer).to eq(customer)
      end

      it "should works for build method" do
        order = Order.on_db(:shard_1).create!(name: "Order Shard1")
        customer = order.build_customer(name: "new Customer")
        order.save

        expect(order.customer).to eq(customer)
        expect(customer.persisted?).to be_truthy
        expect(customer.orders).to eq([order])
      end

      it "should works for create method" do
        order = Order.on_db(:shard_1).create!(name: "Order Shard1")
        customer = order.create_customer(name: "new Customer")
        order.save!

        expect(order.customer).to eq(customer)
        expect(customer.orders).to eq([order])
      end

      context "when calling methods on a collection generated by an association" do
        let(:collection) { @customer_s1.orders }

        before(:each) do
          @customer_s1.orders.create(name: "Order Shard1 #3")
        end

        it "can call collection indexes directly without resetting the collection's current_shard" do
          last_order = collection[1]

          expect(collection.length).to eq(2)
          expect(collection).to eq([collection[0], last_order])
        end

        it "can call methods on the collection without resetting the collection's current_shard" do
          last_order = collection[collection.size - 1]

          expect(collection.length).to eq(2)
          expect(collection).to eq([collection[0], last_order])
        end
      end

      describe "it should works when on_db" do
        before(:each) do
          @order_s1_2 = Order.on_db(:shard_1).create!(name: "Order Shard1 #2")
          expect(@customer_s1.orders.to_set).to eq([@order_s1].to_set)
        end

        it "update_attributes" do
          @customer_s1.update_attributes(order_ids: [@order_s1_2.id, @order_s1.id])
          expect(@customer_s1.orders.to_set).to eq([@order_s1, @order_s1_2].to_set)
        end

        it "update_attribute" do
          @customer_s1.update_attribute(:order_ids, [@order_s1_2.id, @order_s1.id])
          expect(@customer_s1.orders.to_set).to eq([@order_s1, @order_s1_2].to_set)
        end

        it "<<" do
          @customer_s1.orders << @order_s1_2
          expect(@customer_s1.orders.to_set).to eq([@order_s1, @order_s1_2].to_set)
        end

        it "all" do
          order = @customer_s1.orders.build(name: "Builded Order")
          order.save
          i = @customer_s1.orders
          expect(i.to_set).to eq([@order_s1, order].to_set)
          expect(i.reload.all.to_set).to eq([@order_s1, order].to_set)
        end

        it "build" do
          order = @customer_s1.orders.build(name: "Builded Order")
          order.save
          expect(@customer_s1.orders.to_set).to eq([@order_s1, order].to_set)
        end

        it "create" do
          order = @customer_s1.orders.create(name: "Builded Order")
          expect(@customer_s1.orders.to_set).to eq([@order_s1, order].to_set)
        end

        it "count" do
          expect(@customer_s1.orders.count).to eq(1)
          @customer_s1.orders.create(name: "Builded Order")
          expect(@customer_s1.orders.count).to eq(2)
        end

        it "size" do
          expect(@customer_s1.orders.size).to eq(1)
          @customer_s1.orders.create(name: "Builded Order")
          expect(@customer_s1.orders.size).to eq(2)
        end

        it "create!" do
          order = @customer_s1.orders.create!(name: "Builded Order")
          expect(@customer_s1.orders.to_set).to eq([@order_s1, order].to_set)
        end

        it "length" do
          expect(@customer_s1.orders.length).to eq(1)
          @customer_s1.orders.create(name: "Builded Order")
          expect(@customer_s1.orders.length).to eq(2)
        end

        it "empty?" do
          expect(@customer_s1.orders.empty?).to be false
          c = Customer.on_db(:shard_1).create!(name: "Customer1")
          expect(c.orders.empty?).to be true
        end

        it "delete" do
          expect(@customer_s1.orders.empty?).to be false
          @customer_s1.orders.delete(@order_s1)
          @customer_s1.reload
          @order_s1.reload
          expect(@order_s1.customer).to be_nil
          expect(@customer_s1.orders).to eq([])
          expect(@customer_s1.orders.empty?).to be true
        end

        it "delete_all" do
          expect(@customer_s1.orders.empty?).to be false
          @customer_s1.orders.delete_all
          expect(@customer_s1.orders.empty?).to be true
        end

        it "destroy_all" do
          expect(@customer_s1.orders.empty?).to be false
          @customer_s1.orders.destroy_all
          expect(@customer_s1.orders.empty?).to be true
        end

        it "find" do
          expect(@customer_s1.orders.first).to eq(@order_s1)
          @customer_s1.orders.destroy_all
          expect(@customer_s1.orders.first).to be_nil
        end

        it "exists?" do
          expect(@customer_s1.orders.exists?(@order_s1.id)).to be_truthy
          @customer_s1.orders.destroy_all
          expect(@customer_s1.orders.exists?(@order_s1.id)).to be_falsy
        end

        it "uniq" do
          expect(@customer_s1.orders.uniq).to eq([@order_s1])
        end

        it "clear" do
          expect(@customer_s1.orders.empty?).to be false
          @customer_s1.orders.clear
          expect(@customer_s1.orders.empty?).to be true
        end
      end
    end
  end
end

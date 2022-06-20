USE master;
GO
ALTER DATABASE FoodOrderingSystem 
SET SINGLE_USER 
WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE FoodOrderingSystem;
create database FoodOrderingSystem;
use FoodOrderingSystem;
/*============ Creating Tables ==========================*/
--classifying entities
Create table City(
                     CityId int primary Key,
                     CityName nvarchar(100) unique not null
);

Create table Category(
                         CategoryId varchar(100) primary key ,
                         CategoryName nvarchar(100) unique not null
);
Create table PaymentMethod(
                              PaymentId varchar(100) primary key,
                              PaymentName nvarchar(100) unique not null
);
-- component Entities
Create table Vendor(
                       VendorId varchar(100) primary key not null,
                       VendorName nvarchar(100) not null,
                       VendorEmail varchar(100) unique not null,
                       VendorPhoneNumber varchar(20) not null unique check(VendorPhoneNumber not like '%[^0-9]%')
);
Create table Customer(
                         CustomerId varchar(100) primary key,
                         CustomerName nvarchar(100) not null,
                         CustomerEmail varchar(100) not null unique,
                         CustomerPhoneNumber VARCHAR(20) not null unique check(CustomerPhoneNumber not like '%[^0-9]%'),
                         CustomerAddress varchar(100) not null ,
                         CityId int
                             Foreign key (CityId) references City(CityId) not null
);


Create table Rider(

                      RiderId varchar(100) primary key,
                      RiderName nvarchar(100) not null,
                      RiderEmail varchar(100) unique not null,
                      RiderAge int not null check(RiderAge>=18),
                      RiderCNIC varchar (15)check(RiderCNIC not like '%[^0-9]%' ) NOT null,
                      RiderAddress VARCHAR(100) not null,
                      RiderPhoneNumber varchar(20) not null unique check(RiderPhoneNumber not like '%[^0-9]%'),
                      CityId int
                          Foreign key (CityId) references City(CityId) not null,
                      RiderVehicleNumber char(7) unique not null
);
-- Transaction Entities
Create table Kitchen (
                         KitchenId varchar(100) primary key,
                         KitchenName nvarchar(100) not null,
                         VendorId varchar(100)
                             Foreign key(VendorId) REFERENCES Vendor(VendorId) not null,
                         KitchenAddress varchar(100) not null ,
                         CityId int
                             Foreign key (CityId) references City(CityId) not null
);
Create table FoodItems (
                           FoodItemId varchar(100) primary key,
                           FoodItemName nvarchar(100) not null,
                           CategoryId varchar(100)
                               foreign key (CategoryId) references Category(CategoryId) not null,
                           FoodItemPrice int not null,
                           KitchenId varchar(100)
                               foreign key (KitchenId) references Kitchen(KitchenId) not null
);

Create table KitchenRatings(
                               CustomerId varchar(100)
                                   foreign key (CustomerId) references Customer(CustomerId) not NULL,
                               KitchenId VARCHAR(100) NOT NULL FOREIGN KEY (KitchenId) REFERENCES dbo.Kitchen(KitchenId),
                               rating int not NULL CHECK (rating<6)
);
--Create Order (OrderId,Customer,Payment, DateofOrder);

Create table Orders (
                        OrderId varchar(100) primary key ,
                        CustomerId varchar(100) not null
                            foreign key(CustomerId)references Customer(CustomerId),
                        PaymentId varchar(100) not null
                            foreign key (PaymentId) references PaymentMethod(PaymentId),
                        DateofOrder date not null
);
--Create OrderItems (OrderId(FK)(CPK), Food Items(CPK),Quantity,Price,DeliveryCharges);
Create table OrderItems(
                           OrderId varchar(100) not null
                               foreign key (OrderId) references Orders(OrderId),
                           FoodItemId varchar(100) not null
                               foreign key (FoodItemId) references FoodItems(FoodItemid),
                           Quantity int not null CHECK (Quantity>0),
 -- composite primary key
                               CONSTRAINT PK_OrderItem PRIMARY KEY(OrderId,FoodItemId)
);
--Create RiderDeliveryDetails (Did (PK), RiderId(FK),FoodItem(CFK),OrderId(CFK));
Create table RiderDeliveryDetails(
                                     RiderId varchar(100) not null
                                         foreign key (RiderId) references Rider(RiderId),
--composite FKs
                                     FoodItemId varchar(100) not NULL,
                                     OrderId VARCHAR(100) NOT NULL,
                                     CONSTRAINT FK_DeliveryDet FOREIGN KEY
                                         (OrderId, FoodItemId)
                                         REFERENCES dbo.OrderItems (OrderId, FoodItemId),
);

--RiderCommission (Rider(FK),Comission)
Create table RiderCommission(
                                RiderId varchar(100) not null
                                    foreign key (RiderId) references Rider(RiderId),
                                Commission int DEFAULT 0 NOT null
);
--Create RiderPickupDetails(RiderId(FK),OrderID(CFK),FoodItems(CFK),PickupTime);
Create table RiderPickupDetails(
                                   RiderId varchar(100) primary key ,
                                   FoodItemId varchar(100) not NULL,
                                   OrderId VARCHAR(100) NOT NULL,
                                   CONSTRAINT FK_OrderItem FOREIGN KEY
                                       (OrderId, FoodItemId)
                                       REFERENCES dbo.OrderItems (OrderId, FoodItemId),
                                   PickupTime DATE NOT NULL
);




CREATE procedure CreateInvoiceOfIndvidualCustomer (@CustomerId varchar(100))
as
BEGIN
    SELECT  * from GenerateInvoice
    where  CustomerId=@CustomerId;
end
    EXEC CreateInvoiceOfIndvidualCustomer "50961"


    Create procedure CalcTotalBill(@CustomerId varchar(100))
    AS
    BEGIN
        SELECT  sum(Quantity*F.FoodItemPrice) AS TOTAL_BILL
        from OrderItems inner join FoodItems F on F.FoodItemId = OrderItems.FoodItemId
                        inner join Orders O2 on O2.OrderId = OrderItems.OrderId
        WHERE CustomerId = @CustomerId ;
    end

        EXEC CalcTotalBill "04634"

        --City Wise Resturant
        Create Procedure CityWiseResturant AS
        Begin
            SELECT C.CityName,count(KitchenName) AS TOTAL_KITCHEN from Kitchen inner join
                                                                       City C on C.CityId = Kitchen.CityId group by  C.CityName;
        end
--Vendor wise resturant report

            Create Procedure VendorKitchen (@vendorId varchar(100))
            AS BEGIN
                SELECT KitchenName,CityName from Kitchen
                                                     inner join City C2 on C2.CityId = Kitchen.CityId
                                                     inner join Vendor V on V.VendorId = Kitchen.VendorId
                where Kitchen.VendorId=@vendorId

            end
                exec VendorKitchen "38689"


               -- Create PROCEDURE total_CommissionOf_Indvidual_Rider

               create procedure total_commissionOf_IndvidualRider(@riderId varchar(100))AS BEGIN
                   SELECT RiderCommission.RiderId,sum(Commission) AS TOTAL_COMISSION from RiderCommission
                   inner join Rider R2 on R2.RiderId = RiderCommission.RiderId
                   where RiderCommission.RiderId=@riderId group by RiderCommission.RiderId
               end

                   SELECT * from RiderCommission
                   exec total_commissionOf_IndvidualRider "97579"
--                 Create proc indvidual_KitchenSales
                    create procedure indvidual_KitchenSales(@Kitchenid varchar(100))AS
                        BEGIN
                       Select FoodItemName,FoodItemPrice,KitchenId,DateofOrder from OrderItems inner join
                           FoodItems I on I.FoodItemId = OrderItems.FoodItemId
                       inner join Orders O3 on O3.OrderId = OrderItems.OrderId
                       where KitchenId=@Kitchenid group by FoodItemName, FoodItemPrice,KitchenId,DateofOrder;
end

--
--                 Create proc SearchFoodItemByCategory
                    create procedure SearchFoodItemByCategory(@categoryId varchar(100))as begin
                        Select C3.CategoryName,FoodItems.FoodItemName from FoodItems
                        inner join Category C3 on C3.CategoryId = FoodItems.CategoryId
                        where FoodItems.CategoryId= @categoryId
                    end
                    exec SearchFoodItemByCategory "101"


                -- Create proc SearchFoodByPriceRange
                create procedure SearchFoodByPriceRange(@min int , @max int) as
                    begin
                    Select FoodItemName,FoodItemPrice from FoodItems where @min<=FoodItemPrice and @max>=FoodItemPrice;
                end
                    exec SearchFoodByPriceRange "500","1000"
                -- Create proc indvidualriderOrder
                    alter procedure  indvidualRiderOrder(@riderId varchar(100)) as begin
                        SELECT RiderId,RiderDeliveryDetails.OrderId,CustomerId from RiderDeliveryDetails
                       inner join Orders O4 on RiderDeliveryDetails.OrderId = O4.OrderId
                        where RiderId=@riderId
                    end
                        exec indvidualRiderOrder "03997"

                --Reports
                Create View AverageKitchenRatings as
                SELECT K.KitchenName,avg(rating) as AverageRate from KitchenRatings
                                                                         inner join Kitchen K on K.KitchenId = KitchenRatings.KitchenId
                group by KitchenName

--        SELECT * from AverageKitchenRatings;

                Create View SalesReport as
                SELECT DateofOrder ,O2.OrderId,sum(Quantity*F.FoodItemPrice) AS TOTAL_BILL
                from OrderItems inner join FoodItems F on F.FoodItemId = OrderItems.FoodItemId
                                inner join Orders O2 on O2.OrderId = OrderItems.OrderId
                group by DateofOrder ,O2.OrderId;


                Create View GenerateInvoice
                as
                SELECT  DateofOrder,OrderItems.OrderId,OrderItems.FoodItemId,FoodItemName,
                        Quantity ,FoodItemPrice,Quantity*FI.FoodItemPrice
                            AS TotalPrice,(Quantity*FI.FoodItemPrice)*0.2
                            AS Delivery_Charges,O.CustomerId
                from OrderItems
                         inner join FoodItems FI on
                        FI.FoodItemId = OrderItems.FoodItemId
                         inner Join Orders O on
                        OrderItems.OrderId = O.OrderId







CREATE TABLE history_vendor(
vendorId VARCHAR(100),
vendorName VARCHAR(100),
vendorEmail VARCHAR(100),
VendorPhone VARCHAR(100)
);
CREATE TABLE history_Rider(
RiderId VARCHAR(100),
RiderName VARCHAR(100),
RiderEmail VARCHAR(100),
Riderage INT, 
RiderCnic VARCHAR(100),
RiderPhone VARCHAR(100),
RiderAddresss VARCHAR(100),
RiderCity VARCHAR(100),
VehicleNo VARCHAR(100)
);
CREATE TABLE history_customer(
customerId VARCHAR(100),customerName VARCHAR(100), customerEmail VARCHAR(100),
customerPhone VARCHAR(12),customerAddress VARCHAR(100), City VARCHAR(100)
);

CREATE TABLE history_kitchen (
kitchenId varchar(100),
kitchenName VARCHAR(100),
VendorName VARCHAR(100),
kitchenAddress VARCHAR(100),
city VARCHAR(100),
)
CREATE TABLE history_kitchenRating(
kitchenName VARCHAR(100),
CustomerName VARCHAR(100),
rating INT 
);
CREATE TABLE history_OrderItems (
OrderID VARCHAR(100),
FoodItemId VARCHAR(100),
Quantity INT,
Price INT,
DeliveryChargers INT
)

CREATE TABLE history_Orders (
OrderId VARCHAR(100),
CustomerId VARCHAR(100),
PaymentId VARCHAR(100),
DateofOrder DATETIME 
)
--Rider Delivery (Rider Name , Rider Email , Rider Phone , Food Item Name ,Kitchen Name , Kitchen Address, Delivery Time )
CREATE TABLE history_RiderDelivery (
RiderName VARCHAR(100),
RiderEmail VARCHAR(100),
RiderPhone VARCHAR(100),
FoodItem VARCHAR(100),
kitchenName VARCHAR(100),
KitcheAddress VARCHAR(100),
DeliveryTime VARCHAR(100),
Comission INT 
);
CREATE TABLE history_riderPickup(
RiderName VARCHAR(100),
RiderEmail VARCHAR(100),
RiderPhone VARCHAR(100),
FoodItem VARCHAR(100),
KitchenName VARCHAR(100),
KitchenAddress VARCHAR(100),
PickupTime VARCHAR(100)
);

CREATE TABLE history_foodItems(
FoodName VARCHAR(100),
Category VARCHAR(100),
Price INT,
foodItemId VARCHAR(100),
)


























CREATE TRIGGER insert_history_kitchen_rating ON KitchenRatings
    AFTER INSERT
    AS
BEGIN
    DECLARE @KitchenId VARCHAR(100)
    DECLARE @CustomerId VARCHAR(100)
    DECLARE @rating INT
    SELECT @KitchenId = KitchenId FROM INSERTED;
    SELECT @CustomerId = CustomerId FROM INSERTED;
    SELECT @rating = rating FROM INSERTED;

    INSERT INTO dbo.history_kitchenRating
    (
        kitchenName,
        CustomerName,
        rating
    )
    VALUES
        (   @KitchenId, -- kitchenName - varchar(100)
            @CustomerId, -- CustomerName - varchar(100)
            @rating  -- rating - int
        )

END
    DELETE FROM dbo.history_kitchenRating;

    SELECT * FROM dbo.history_kitchenRating

    INSERT INTO dbo.KitchenRatings
    (
        CustomerId,
        KitchenId,
        rating
    )
    VALUES
        (   '00915', -- CustomerId - varchar(100)
            '00022', -- KitchenId - varchar(100)
            5   -- ratings - int
        )

    SELECT * FROM dbo.history_kitchenRating
    SELECT *FROM kitchen;
    DROP TRIGGER insert_history_kitchen_rating;




    Create TRIGGER insert_kitchen_history ON kitchen
        AFTER INSERT
        AS
        BEGIN

            DECLARE @kitchenId VARCHAR(100)
            DECLARE @kitchenName NVARCHAR(100)
            DECLARE @VendorId VARCHAR(100)
            DECLARE @kitchenAddress VARCHAR(100)
            DECLARE @cityId INT

            SELECT @KitchenId = KitchenId FROM INSERTED;
            SELECT @kitchenName = kitchenName FROM inserted;
            SELECT @VendorId = VendorId FROM inserted;
            SELECT @kitchenAddress = kitchenAddress FROM inserted;
            SELECT @cityId = CityId FROM inserted;

            INSERT INTO dbo.history_kitchen
            (
                VendorName,
                kitchenId,
                KitchenName,
                kitchenAddress,
                city
            )

            VALUES
                (
                    @VendorId,
                    @kitchenId,
                    @kitchenName,
                    @kitchenAddress,
                    @cityId
                )

        END
        SELECT * FROM dbo.history_kitchen
        SELECT * FROM city;
        INSERT INTO kitchen


        (
            kitchenId,
            kitchenName,
            KitchenAddress,
            CityId,
            VendorId
        )
        VALUES
            (
                '00915', -- Id - varchar(100)
                'helina', -- name - varchar(100)
                'Model Town', -- address
                '47',  -- city
                '00896'
            )



--ALTER TABLE OrderItems DROP COLUMN DeliveryCharges;
     --   ALTER TABLE history_kitchen ADD  foodItemId varchar(100);

       create TRIGGER Food_items_history ON FoodItems
            AFTER INSERT
            AS
            BEGIN
                DECLARE @FoodItemId VARCHAR(100)
                DECLARE @FooditemName NVARCHAR(100)
                DECLARE @Categoryid VARCHAR(100)
                DECLARE @FooditemPrice INT

                SELECT @FoodItemId = FoodItemId FROM inserted;
                SELECT @FooditemName = FooditemName FROM inserted;
                SELECT @Categoryid = Categoryid FROM inserted;
                SELECT @FooditemPrice = FooditemPrice FROM inserted;

                INSERT INTO dbo.history_foodItems
                (
                    FoodName,
                    category,
                    Price,
                    foodItemId
                )
                VALUES
                    (
                        @Categoryid,
                        @FooditemPrice,
                        @FooditemPrice,
                        @FoodItemId
                    )
            END
            SELECT * FROM dbo.history_foodItems
            INSERT INTO history_FoodItems
            (
                FoodItemId,
                FoodName,
                Category,
                Price
            )
            VALUES
                (
                    '00040',
                    'baryani',
                    '18',
                    '2100'
                )
            SELECT *FROM fooditems;
--           Create TABLE history_kitchen DROP COLUMN foodName, Category, Price, foodItemId;


            CREATE TABLE history_foodItems(
                                              FoodName VARCHAR(100),
                                              Category VARCHAR(100),
                                              Price INT,
                                              foodItemId VARCHAR(100),
            )


            CREATE TRIGGER Insert_history_customer ON Customer
                AFTER INSERT
                AS
            BEGIN
                DECLARE @customerId VARCHAR(100)
                DECLARE @customerName NVARCHAR(100)
                DECLARE @customerPhoneNumber VARCHAR(100)
                DECLARE @customerEmail VARCHAR(100)
                DECLARE @customerAddress VARCHAR(100)
                DECLARE @cityId INT

                SELECT @CustomerId = CustomerId FROM inserted
                SELECT @customerName = customerName FROM inserted
                SELECT @customerPhoneNumber = customerPhoneNumber FROM inserted
                SELECT @customerEmail = customerEmail FROM inserted
                SELECT @customerAddress = customerAddress FROM inserted
                SELECT @cityId = cityId FROM inserted

                INSERT INTO dbo.history_customer
                (
                    customerId,
                    customerName,
                    customerEmail,
                    customerPhone,
                    customerAddress,
                    city
                )
                VALUES
                    (
                        @CustomerId,
                        @customerName,
                        @customerEmail,
                        @customerPhoneNumber,
                        @customerAddress,
                        @cityId
                    )

            END
                SELECT *FROM dbo.history_customer;
                INSERT INTO Customer
                (
                    customerId,
                    customerName,
                    customerEmail,
                    customerPhoneNumber,
                    customerAddress,
                    cityId
                )

                VALUES
                    (
                        '134',
                        'Muhammad Hamza',
                        'hama@gamil.com',
                        '03215698374',
                        'odel town',
                        '6'
                    )

                SELECT *FROM dbo.history_customer;

                DELETE FROM dbo.history_customer;



                CREATE TRIGGER Insert_history_Rider ON Rider
                    AFTER INSERT
                    AS
                BEGIN
                    DECLARE @RiderId VARCHAR(100)
                    DECLARE @RiderName NVARCHAR(100)
                    DECLARE @RiderPhoneNumber VARCHAR(100)
                    DECLARE @RiderEmail VARCHAR(100)
                    DECLARE @RiderAddress VARCHAR(100)
                    DECLARE @CityId INT
                    DECLARE @RiderCNIC VARCHAR(15)
                    DECLARE @RiderAge INT
                    DECLARE @RiderVehicleNumber CHAR(7)

                    SELECT @RiderId = RiderId FROM inserted
                    SELECT @RiderName = RiderName FROM inserted
                    SELECT @RiderPhoneNumber= RiderPhoneNumber FROM inserted
                    SELECT @RiderEmail = RiderEmail FROM inserted
                    SELECT @RiderAddress = RiderAddress FROM inserted
                    SELECT @CityId= CityId FROM inserted
                    SELECT @RiderCNIC = RiderCNIC FROM inserted
                    SELECT @RiderAge = RiderAge FROM inserted
                    SELECT @RiderVehicleNumber = RiderVehicleNumber FROM inserted

                    INSERT INTO dbo.history_Rider
                    (
                        RiderId,
                        RiderName,
                        RiderEmail,
                        Riderage,
                        RiderPhone,
                        RiderCity,
                        RiderCnic,
                        VehicleNo,
                        RiderAddresss
                    )
                    VALUES
                        (
                            @RiderId,
                            @RiderName,
                            @RiderEmail,
                            @Riderage,
                            @RiderPhoneNumber,
                            @CityId,
                            @RiderCnic,
                            @RiderVehicleNumber,
                            @RiderAddress
                        )
                END
                    DELETE FROM dbo.history_Rider;
                    SELECT * FROM dbo.history_Rider;
                    INSERT INTO dbo.Rider
                    (
                        RiderId,
                        RiderName,
                        RiderEmail,
                        Riderage,
                        RiderPhoneNumber,
                        CityId,
                        RiderCnic,
                        RiderVehicleNumber,
                        RiderAddress
                    )
                    VALUES
                        ('293',
                         'udguiwdw',
                         'hamza@dhe',
                         '19',
                         '3833931',
                         '23',
                         '836467',
                         '2332',
                         'fdsf2'
                        )

                    CREATE TABLE history_OrderItems (
                                                        OrderID VARCHAR(100),
                                                        FoodItemId VARCHAR(100),
                                                        Quantity INT,

                    )

--                     ALTER TABLE dbo.history_OrderItems DROP COLUMN DeliveryChargers;
--                     ALTER TABLE dbo.history_OrderItems DROP COLUMN Price;


                    CREATE TRIGGER Insert_OrderItems_History ON OrderItems
                        AFTER INSERT
                        AS
                    BEGIN

                        DECLARE @OrderId VARCHAR(100)
                        DECLARE @FoodItemId VARCHAR(100)
                        DECLARE @Quantity INT


                        SELECT @OrderId = OrderId FROM Inserted
                        SELECT @FoodItemId = FoodItemID FROM Inserted
                        SELECT @Quantity = Quantity FROM Inserted


                        INSERT INTO dbo.history_OrderItems
                        (
                            OrderID,
                            FoodItemId,
                            Quantity

                        )
                        VALUES
                            (   @OrderId, -- OrderID - varchar(100)
                                @FoodItemId, -- FoodItemId - varchar(100)
                                @Quantity -- Quantity - int

                            )

                    END
                        SELECT * FROM dbo.history_OrderItems;

--                         INSERT INTO dbo.OrderItems
--                         (
--                             OrderId,
--                             FoodItemId,
--                             Quantity,
--                             Price,
--                             DeliveryCharges
--                         )
--                         VALUES
--                             (   '00579', -- OrderId - varchar(100)
--                                 '00040', -- FoodItemId - varchar(100)
--                                 43,  -- Quantity - int
--                                 543,  -- Price - int
--                                 320   -- DeliveryCharges - int
--                             )



                        CREATE TABLE history_Orders (
                                                        OrderId VARCHAR(100),
                                                        CustomerId VARCHAR(100),
                                                        PaymentId VARCHAR(100),
                                                        DateofOrder DATETIME
                        )

                        Create TRIGGER Insert_Order_History ON Orders
                            AFTER INSERT
                            AS
                            BEGIN
                                DECLARE @OrderID VARCHAR(100)
                                DECLARE @CustomerId VARCHAR(100)
                                DECLARE @PaymentId VARCHAR(100)
                                DECLARE @DateofOrder DATETIME

                                SELECT @OrderId = OrderID FROM Inserted
                                SELECT @CustomerId = CustomerId FROM Inserted
                                SELECT @PaymentId = PaymentId FROM Inserted
                                SELECT @DateofOrder = DateofOrder FROM Inserted

                                INSERT INTO dbo.history_orders
                                (
                                    OrderId,
                                    CustomerId,
                                    PaymentId,
                                    DateOfOrder
                                )
                                VALUES
                                    (   @OrderId, -- orderId - varchar(100)
                                        @CustomerID, -- CustomerName - varchar(100)
                                        @PaymentId, -- Payment - varchar(100)
                                        @DateofOrder -- DateOfOrder - datetime
                                    )

                            END

                            SELECT * FROM Orders;

                            INSERT INTO Orders
                            (
                                OrderId,
                                CustomerId,
                                PaymentId,
                                DateofOrder
                            )
                            VALUES
                                (   '123',       -- OrderId - varchar(100)
                                    '00863',       -- CustomerId - varchar(100)
                                    '19435',       -- PaymentId - varchar(100)
                                    GETDATE() -- DateofOrder - datetime
                                )

                            SELECT * FROM dbo.Customer;




--                             ALTER TRIGGER insert_in_rider_com ON Rider
--                                 AFTER INSERT
--                                 AS
--                                 BEGIN
--                                     DECLARE @RiderId VARCHAR(100)
--
--                                     SELECT @RiderId = RiderId FROM Inserted
--
--                                     INSERT INTO dbo.RiderCommission
--                                     (
--                                         RiderId,
--                                         Commission
--                                     )
--                                     VALUES
--                                         (   '00471',     -- RiderId - varchar(100)
--                                             DEFAULT -- Commission - int
--                                         )
--                                 END
--                                 SELECT RiderId,Commission FROM dbo.RiderCommission WHERE RiderId = '004695';
--
--                                 INSERT INTO dbo.Rider
--                                 (
--                                     RiderId,
--                                     RiderName,
--                                     RiderEmail,
--                                     RiderAge,
--                                     RiderCNIC,
--                                     RiderAddress,
--                                     RiderPhoneNumber,
--                                     CityId,
--                                     RiderVehicleNumber
--                                 )
--                                 VALUES
--                                     (   '004695',  -- RiderId - varchar(100)
--                                         N'arsalan', -- RiderName - nvarchar(100)
--                                         'hamzapaktan@gamil.com',  -- RiderEmail - varchar(100)
--                                         19,   -- RiderAge - int
--                                         '3520245193689',  -- RiderCNIC - varchar(15)
--                                         'lahore',  -- RiderAddress - varchar(100)
--                                         '0423564122',  -- RiderPhoneNumber - varchar(20)
--                                         25,   -- CityId - int
--                                         '02436'   -- RiderVehicleNumber - char(7)
--                                     )
                                SELECT * FROM dbo.Rider




# Project Functions, CRUDs and Database Schema

# Database Schema (Models)

## Entity: Business

- Id (Guid)
- BusinessName (string)
- Email (string?)
- GoogleId (string?)
- LogoUrl (string?)
- CoverPhotoUrl (string?)
- PhoneNumber (string?)
- Address (string?)
- IndustryType (string?)
- RegistrationNumber (string?)
- Bio (string?)
- Description (string?)
- WebsiteUrl (string?)
- CreatedAt (DateTime)
- UpdatedAt (DateTime?)
- IsVerified (bool)
- Status (string)
- VerificationNote (string?)
- VerifiedAt (DateTime?)
- UserId (Guid?)
- IsAdmin (bool)


## Entity: ChatMessage

- Id (Guid)
- ListingId (Guid)
- Listing (MaterialListing?)
- SenderId (Guid)
- Sender (Business?)
- ReceiverId (Guid)
- Receiver (Business?)
- Content (string)
- CreatedAt (DateTime)


## Entity: Delivery

- Id (Guid)
- MaterialTransactionId (Guid?)
- ProductOrderId (Guid?)
- Method (DeliveryMethod)
- Location (string?)
- CreatedAt (DateTime)
- UpdatedAt (DateTime?)
- Status (DeliveryStatus)
- CurrentLatitude (double?)
- CurrentLongitude (double?)
- LocationUpdatedAt (DateTime?)
- MaterialTransaction (MaterialTransaction?)
- ProductOrder (ProductOrder?)


## Entity: DeliveryLocation

- Id (Guid)
- BusinessId (Guid)
- Business (Business?)
- Label (string)
- Address (string)
- Latitude (double?)
- Longitude (double?)
- CreatedAt (DateTime)
- UpdatedAt (DateTime)


## Entity: DeviceToken

- Id (Guid)
- BusinessId (Guid)
- Business (Business?)
- Token (string)
- CreatedAt (DateTime)


## Entity: Inventory

- Id (Guid)
- ProductId (Guid)
- Quantity (int)
- IsAvailable (bool)
- Product (Product?)


## Entity: MatchSuggestion

- Id (Guid)
- WorkflowId (Guid)
- Workflow (MatchWorkflow?)
- HaveListingId (Guid)
- HaveListing (MaterialListing?)
- NeedListingId (Guid)
- NeedListing (MaterialListing?)
- Score (decimal)
- Reasons (List<string>)
- Warnings (List<string>)
- QuantityCoverage (decimal?)
- DistanceKm (double?)
- HaveOwnerDecision (string)
- NeedOwnerDecision (string)
- CreatedAt (DateTime)
- UpdatedAt (DateTime)


## Entity: MatchWorkflow

- Id (Guid)
- ListingId (Guid)
- Listing (MaterialListing?)
- OwnerBusinessId (Guid)
- State (string)
- Outcome (string?)
- Reason (string?)
- StateHistoryJson (string)
- TraceJson (string?)
- SuggestionCount (int)
- CreatedAt (DateTime)
- CompletedAt (DateTime?)


## Entity: MaterialListing

- Id (Guid)
- BusinessId (Guid)
- PostedAsBusinessId (Guid?)
- Title (string)
- Category (string)
- Description (string)
- Quantity (string)
- Unit (string)
- Location (string)
- Price (decimal)
- PriceUnit (string)
- DeliveryMethod (string)
- SellerDeliveryAvailable (bool)
- Availability (string?)
- Condition (string?)
- Type (ListingType)
- Status (ListingStatus)
- CreatedAt (DateTime)
- UpdatedAt (DateTime?)
- ImageUrl (string?)
- ImageUrls (List<string>)
- Business (Business?)
- PostedAsBusiness (Business?)
- Transactions (List<MaterialTransaction>)


## Entity: MaterialTransaction

- Id (Guid)
- MaterialListingId (Guid)
- BuyerBusinessId (Guid)
- SellerBusinessId (Guid)
- Quantity (decimal)
- Unit (string)
- UnitPrice (decimal)
- TotalAmount (decimal)
- Status (MaterialTransactionStatus)
- CreatedAt (DateTime)
- UpdatedAt (DateTime?)
- MaterialListing (MaterialListing?)
- BuyerBusiness (Business?)
- SellerBusiness (Business?)
- Delivery (Delivery?)
- StatusHistory (List<MaterialTransactionStatusHistory>)


## Entity: MaterialTransactionStatusHistory

- Id (Guid)
- MaterialTransactionId (Guid)
- Status (MaterialTransactionStatus)
- ChangedByBusinessId (Guid?)
- Note (string?)
- CreatedAt (DateTime)
- MaterialTransaction (MaterialTransaction?)
- ChangedByBusiness (Business?)


## Entity: Product

- Id (Guid)
- CategoryId (Guid)
- BusinessId (Guid)
- PostedAsBusinessId (Guid?)
- Name (string)
- Description (string)
- MaterialType (string)
- Price (decimal)
- IsActive (bool)
- SellerDeliveryAvailable (bool)
- CreatedAt (DateTime)
- Category (ProductCategory?)
- Business (Business?)
- PostedAsBusiness (Business?)
- Inventory (Inventory?)
- Images (List<ProductImage>)
- OrderItems (List<ProductOrderItem>)


## Entity: ProductCategory

- Id (Guid)
- Name (string)
- Description (string?)
- IsActive (bool)
- Products (List<Product>)


## Entity: ProductImage

- Id (Guid)
- ProductId (Guid)
- ImageUrl (string)
- IsPrimary (bool)
- DisplayOrder (int)
- Product (Product?)


## Entity: ProductOrder

- Id (Guid)
- BuyerBusinessId (Guid)
- SellerBusinessId (Guid)
- Status (ProductOrderStatus)
- TotalAmount (decimal)
- CreatedAt (DateTime)
- UpdatedAt (DateTime?)
- BuyerBusiness (Business?)
- SellerBusiness (Business?)
- Delivery (Delivery?)
- Items (List<ProductOrderItem>)
- StatusHistory (List<ProductOrderStatusHistory>)


## Entity: ProductOrderItem

- Id (Guid)
- ProductOrderId (Guid)
- ProductId (Guid)
- ProductName (string)
- Quantity (int)
- UnitPrice (decimal)
- LineTotal (decimal)
- CreatedAt (DateTime)
- ProductOrder (ProductOrder?)
- Product (Product?)


## Entity: ProductOrderStatusHistory

- Id (Guid)
- ProductOrderId (Guid)
- Status (ProductOrderStatus)
- ChangedByBusinessId (Guid?)
- Note (string?)
- CreatedAt (DateTime)
- ProductOrder (ProductOrder?)
- ChangedByBusiness (Business?)


## Entity: RefreshToken

- Id (Guid)
- Token (string)
- JwtId (string)
- CreationDate (DateTime)
- ExpiryDate (DateTime)
- Used (bool)
- Invalidated (bool)
- BusinessId (Guid)
- Business (Business)


# Controllers and CRUD Operations

## Controller: AdminController

- [HttpGet] AiWorkflows
- [HttpGet] AiWorkflow
- [HttpGet] Me
- [HttpGet] Summary
- [HttpGet] List
- [HttpPost] Approve
- [HttpPost] Reject


## Controller: AuthController

- [HttpPost] GoogleLogin
- [HttpPost] GoogleCodeLogin
- [HttpPost] RefreshToken


## Controller: BusinessController



## Controller: BusinessProfilesController

- [HttpPost] CreateProfile
- [HttpGet] GetById
- [HttpGet] GetByUserId
- [HttpGet] GetMyProfiles
- [HttpGet] GetAll
- [HttpPut] UpdateProfile
- [HttpDelete] DeleteImage
- [HttpDelete] DeleteProfile
- [HttpGet] GetProfilePosts


## Controller: ChatController

- [HttpGet] GetChatHistory
- [HttpGet] GetInbox


## Controller: DeliveriesController

- [HttpGet] Mine
- [HttpPost] Start
- [HttpPut] UpdatePosition
- [HttpPost] Delivered


## Controller: DeliveryLocationsController

- [HttpGet] List
- [HttpGet] Get
- [HttpPost] Create
- [HttpPut] Update
- [HttpDelete] Delete


## Controller: DeliveryRoutesController

- [HttpPost] Calculate
- [HttpGet] Reverse
- [HttpGet] Geocode


## Controller: InternalAiController

- [HttpGet] Post
- [HttpPost] Candidates
- [HttpPost] Distance
- [HttpPost] State


## Controller: InventoryController

- [HttpGet] GetInventory
- [HttpPost] CreateInventory
- [HttpPut] UpdateInventory
- [HttpDelete] DeleteInventory


## Controller: MatchesController

- [HttpGet] Mine
- [HttpGet] Activity
- [HttpPost] Connect
- [HttpPost] Dismiss
- [HttpPost] RunForListing
- [HttpGet] Status


## Controller: MaterialListingsController

- [HttpGet] GetAll
- [HttpGet] GetByBusiness
- [HttpGet] GetById
- [HttpPost] Create
- [HttpPut] Update
- [HttpPost] AddImages


## Controller: MaterialTransactionsController

- [HttpPost] Create
- [HttpGet] GetById
- [HttpGet] GetBuyerHistory
- [HttpGet] GetSellerHistory
- [HttpGet] GetTimeline
- [HttpGet] GetDelivery
- [HttpPut] UpdateDetails
- [HttpPut] UpdateLocation
- [HttpPost] Accept
- [HttpPost] Reject
- [HttpPost] Processing
- [HttpPost] Ready
- [HttpPost] Complete
- [HttpPost] Cancel


## Controller: NotificationsController

- [HttpPost] RegisterDeviceToken


## Controller: ProductCategoriesController

- [HttpGet] GetAll
- [HttpGet] GetById
- [HttpPost] Create
- [HttpPut] Update
- [HttpDelete] Delete


## Controller: ProductImagesController

- [HttpGet] GetImages
- [HttpPost] CreateImage
- [HttpPut] UpdateImage
- [HttpDelete] DeleteImage


## Controller: ProductOrdersController

- [HttpPost] Create
- [HttpGet] GetById
- [HttpGet] GetBuyerHistory
- [HttpGet] GetSellerHistory
- [HttpGet] GetTimeline
- [HttpGet] GetDelivery
- [HttpPut] UpdateLocation
- [HttpPost] Confirm
- [HttpPost] Processing
- [HttpPost] Ready
- [HttpPost] Complete
- [HttpPost] Deliver
- [HttpPost] Cancel


## Controller: ProductsController

- [HttpGet] GetProducts
- [HttpGet] GetProduct
- [HttpPost] CreateProduct
- [HttpPut] UpdateProduct
- [HttpDelete] DisableProduct
- [HttpPost] PurchaseProduct


# Services and Functions

## Service: BusinessProfileService

- CreateAsync
- GetByIdAsync
- GetByUserIdAsync
- GetMyProfilesAsync
- GetAllAsync
- UpdateAsync
- EnsureCanPostAsAsync
- UploadImageAsync
- DeleteImageAsync
- DeleteAsync
- GetPostsByBusinessIdAsync


## Service: BusinessService

- GetProfileAsync
- UpdateProfileAsync


## Service: BusinessVerificationService

- GetSummaryAsync
- GetRequestsAsync
- ApproveAsync
- RejectAsync


## Service: CategoryService

- GetAllAsync
- GetByIdAsync
- CreateAsync
- UpdateAsync
- DeleteAsync


## Service: DeliveryLocationService

- ListAsync
- GetAsync
- SaveAsync
- DeleteAsync


## Service: DeliveryRouteService

- DeliveryRouteRequest
- DeliveryRouteDto
- GeocodedPlaceDto
- CalculateAsync
- ReverseGeocodeAsync
- GeocodeAsync


## Service: DeliveryTrackingService

- GetForSellerAsync
- StartAsync
- UpdatePositionAsync
- MarkDeliveredAsync


## Service: InventoryService

- GetByProductIdAsync
- CreateAsync
- UpdateAsync
- DeleteAsync


## Service: MaterialListingService

- GetAllAsync
- GetByBusinessAsync
- GetByIdAsync
- CreateAsync
- UpdateAsync
- ImageCountAsync
- AddImagesAsync
- GetOwnerIdAsync
- ChangeStatusAsync


## Service: MaterialTransactionService

- CreateAsync
- GetByIdAsync
- GetBuyerHistoryAsync
- GetSellerHistoryAsync
- ChangeStatusAsync
- UpdateDetailsAsync
- UpdateLocationAsync


## Service: NotificationService

- SendPushNotificationAsync


## Service: ProductImageService

- GetByProductIdAsync
- CreateAsync
- UpdateAsync
- DeleteAsync


## Service: ProductOrderService

- CreateAsync
- GetByIdAsync
- GetBuyerHistoryAsync
- GetSellerHistoryAsync
- ChangeStatusAsync
- UpdateLocationAsync


## Service: ProductService

- GetProductsAsync
- GetByIdAsync
- CreateAsync
- UpdateAsync
- DisableAsync
- PurchaseAsync


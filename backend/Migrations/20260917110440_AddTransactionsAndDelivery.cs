using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class AddTransactionsAndDelivery : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "SellerDeliveryAvailable",
                table: "Products",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "SellerDeliveryAvailable",
                table: "MaterialListings",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "MaterialTransactions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MaterialListingId = table.Column<Guid>(type: "uuid", nullable: false),
                    BuyerBusinessId = table.Column<Guid>(type: "uuid", nullable: false),
                    SellerBusinessId = table.Column<Guid>(type: "uuid", nullable: false),
                    Quantity = table.Column<decimal>(type: "numeric(12,3)", precision: 12, scale: 3, nullable: false),
                    Unit = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    UnitPrice = table.Column<decimal>(type: "numeric(12,2)", precision: 12, scale: 2, nullable: false),
                    TotalAmount = table.Column<decimal>(type: "numeric(12,2)", precision: 12, scale: 2, nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MaterialTransactions", x => x.Id);
                    table.CheckConstraint("CK_MaterialTransactions_Amounts", "\"UnitPrice\" >= 0 AND \"TotalAmount\" >= 0");
                    table.CheckConstraint("CK_MaterialTransactions_DifferentParties", "\"BuyerBusinessId\" <> \"SellerBusinessId\"");
                    table.CheckConstraint("CK_MaterialTransactions_Quantity", "\"Quantity\" > 0");
                    table.ForeignKey(
                        name: "FK_MaterialTransactions_Businesses_BuyerBusinessId",
                        column: x => x.BuyerBusinessId,
                        principalTable: "Businesses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MaterialTransactions_Businesses_SellerBusinessId",
                        column: x => x.SellerBusinessId,
                        principalTable: "Businesses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MaterialTransactions_MaterialListings_MaterialListingId",
                        column: x => x.MaterialListingId,
                        principalTable: "MaterialListings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ProductOrders",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BuyerBusinessId = table.Column<Guid>(type: "uuid", nullable: false),
                    SellerBusinessId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    TotalAmount = table.Column<decimal>(type: "numeric(12,2)", precision: 12, scale: 2, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProductOrders", x => x.Id);
                    table.CheckConstraint("CK_ProductOrders_DifferentParties", "\"BuyerBusinessId\" <> \"SellerBusinessId\"");
                    table.CheckConstraint("CK_ProductOrders_TotalAmount", "\"TotalAmount\" >= 0");
                    table.ForeignKey(
                        name: "FK_ProductOrders_Businesses_BuyerBusinessId",
                        column: x => x.BuyerBusinessId,
                        principalTable: "Businesses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ProductOrders_Businesses_SellerBusinessId",
                        column: x => x.SellerBusinessId,
                        principalTable: "Businesses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "MaterialTransactionStatusHistories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MaterialTransactionId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    ChangedByBusinessId = table.Column<Guid>(type: "uuid", nullable: true),
                    Note = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MaterialTransactionStatusHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MaterialTransactionStatusHistories_Businesses_ChangedByBusi~",
                        column: x => x.ChangedByBusinessId,
                        principalTable: "Businesses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MaterialTransactionStatusHistories_MaterialTransactions_Mat~",
                        column: x => x.MaterialTransactionId,
                        principalTable: "MaterialTransactions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Deliveries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MaterialTransactionId = table.Column<Guid>(type: "uuid", nullable: true),
                    ProductOrderId = table.Column<Guid>(type: "uuid", nullable: true),
                    Method = table.Column<int>(type: "integer", nullable: false),
                    Location = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Deliveries", x => x.Id);
                    table.CheckConstraint("CK_Deliveries_ExactlyOneParent", "(\"MaterialTransactionId\" IS NOT NULL AND \"ProductOrderId\" IS NULL) OR (\"MaterialTransactionId\" IS NULL AND \"ProductOrderId\" IS NOT NULL)");
                    table.ForeignKey(
                        name: "FK_Deliveries_MaterialTransactions_MaterialTransactionId",
                        column: x => x.MaterialTransactionId,
                        principalTable: "MaterialTransactions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Deliveries_ProductOrders_ProductOrderId",
                        column: x => x.ProductOrderId,
                        principalTable: "ProductOrders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProductOrderItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductOrderId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Quantity = table.Column<int>(type: "integer", nullable: false),
                    UnitPrice = table.Column<decimal>(type: "numeric(12,2)", precision: 12, scale: 2, nullable: false),
                    LineTotal = table.Column<decimal>(type: "numeric(12,2)", precision: 12, scale: 2, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProductOrderItems", x => x.Id);
                    table.CheckConstraint("CK_ProductOrderItems_Amounts", "\"UnitPrice\" >= 0 AND \"LineTotal\" >= 0");
                    table.CheckConstraint("CK_ProductOrderItems_Quantity", "\"Quantity\" > 0");
                    table.ForeignKey(
                        name: "FK_ProductOrderItems_ProductOrders_ProductOrderId",
                        column: x => x.ProductOrderId,
                        principalTable: "ProductOrders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ProductOrderItems_Products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ProductOrderStatusHistories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductOrderId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    ChangedByBusinessId = table.Column<Guid>(type: "uuid", nullable: true),
                    Note = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProductOrderStatusHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProductOrderStatusHistories_Businesses_ChangedByBusinessId",
                        column: x => x.ChangedByBusinessId,
                        principalTable: "Businesses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ProductOrderStatusHistories_ProductOrders_ProductOrderId",
                        column: x => x.ProductOrderId,
                        principalTable: "ProductOrders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Deliveries_MaterialTransactionId",
                table: "Deliveries",
                column: "MaterialTransactionId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Deliveries_ProductOrderId",
                table: "Deliveries",
                column: "ProductOrderId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MaterialTransactions_BuyerBusinessId_CreatedAt",
                table: "MaterialTransactions",
                columns: new[] { "BuyerBusinessId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_MaterialTransactions_MaterialListingId",
                table: "MaterialTransactions",
                column: "MaterialListingId");

            migrationBuilder.CreateIndex(
                name: "IX_MaterialTransactions_SellerBusinessId_CreatedAt",
                table: "MaterialTransactions",
                columns: new[] { "SellerBusinessId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_MaterialTransactions_Status",
                table: "MaterialTransactions",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_MaterialTransactionStatusHistories_ChangedByBusinessId",
                table: "MaterialTransactionStatusHistories",
                column: "ChangedByBusinessId");

            migrationBuilder.CreateIndex(
                name: "IX_MaterialTransactionStatusHistories_MaterialTransactionId_Cr~",
                table: "MaterialTransactionStatusHistories",
                columns: new[] { "MaterialTransactionId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ProductOrderItems_ProductId",
                table: "ProductOrderItems",
                column: "ProductId");

            migrationBuilder.CreateIndex(
                name: "IX_ProductOrderItems_ProductOrderId_ProductId",
                table: "ProductOrderItems",
                columns: new[] { "ProductOrderId", "ProductId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ProductOrders_BuyerBusinessId_CreatedAt",
                table: "ProductOrders",
                columns: new[] { "BuyerBusinessId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ProductOrders_SellerBusinessId_CreatedAt",
                table: "ProductOrders",
                columns: new[] { "SellerBusinessId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ProductOrders_Status",
                table: "ProductOrders",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_ProductOrderStatusHistories_ChangedByBusinessId",
                table: "ProductOrderStatusHistories",
                column: "ChangedByBusinessId");

            migrationBuilder.CreateIndex(
                name: "IX_ProductOrderStatusHistories_ProductOrderId_CreatedAt",
                table: "ProductOrderStatusHistories",
                columns: new[] { "ProductOrderId", "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Deliveries");

            migrationBuilder.DropTable(
                name: "MaterialTransactionStatusHistories");

            migrationBuilder.DropTable(
                name: "ProductOrderItems");

            migrationBuilder.DropTable(
                name: "ProductOrderStatusHistories");

            migrationBuilder.DropTable(
                name: "MaterialTransactions");

            migrationBuilder.DropTable(
                name: "ProductOrders");

            migrationBuilder.DropColumn(
                name: "SellerDeliveryAvailable",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "SellerDeliveryAvailable",
                table: "MaterialListings");
        }
    }
}

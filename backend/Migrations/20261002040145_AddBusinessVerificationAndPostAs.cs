using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class AddBusinessVerificationAndPostAs : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "PostedAsBusinessId",
                table: "Products",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "PostedAsBusinessId",
                table: "MaterialListings",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsAdmin",
                table: "Businesses",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "VerificationNote",
                table: "Businesses",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "VerifiedAt",
                table: "Businesses",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Products_PostedAsBusinessId",
                table: "Products",
                column: "PostedAsBusinessId");

            migrationBuilder.CreateIndex(
                name: "IX_MaterialListings_PostedAsBusinessId",
                table: "MaterialListings",
                column: "PostedAsBusinessId");

            migrationBuilder.CreateIndex(
                name: "IX_Businesses_Status",
                table: "Businesses",
                column: "Status");

            migrationBuilder.AddForeignKey(
                name: "FK_MaterialListings_Businesses_PostedAsBusinessId",
                table: "MaterialListings",
                column: "PostedAsBusinessId",
                principalTable: "Businesses",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Products_Businesses_PostedAsBusinessId",
                table: "Products",
                column: "PostedAsBusinessId",
                principalTable: "Businesses",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_MaterialListings_Businesses_PostedAsBusinessId",
                table: "MaterialListings");

            migrationBuilder.DropForeignKey(
                name: "FK_Products_Businesses_PostedAsBusinessId",
                table: "Products");

            migrationBuilder.DropIndex(
                name: "IX_Products_PostedAsBusinessId",
                table: "Products");

            migrationBuilder.DropIndex(
                name: "IX_MaterialListings_PostedAsBusinessId",
                table: "MaterialListings");

            migrationBuilder.DropIndex(
                name: "IX_Businesses_Status",
                table: "Businesses");

            migrationBuilder.DropColumn(
                name: "PostedAsBusinessId",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "PostedAsBusinessId",
                table: "MaterialListings");

            migrationBuilder.DropColumn(
                name: "IsAdmin",
                table: "Businesses");

            migrationBuilder.DropColumn(
                name: "VerificationNote",
                table: "Businesses");

            migrationBuilder.DropColumn(
                name: "VerifiedAt",
                table: "Businesses");
        }
    }
}

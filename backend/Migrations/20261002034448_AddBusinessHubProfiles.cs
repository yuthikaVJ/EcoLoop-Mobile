using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class AddBusinessHubProfiles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Bio",
                table: "Businesses",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CoverPhotoUrl",
                table: "Businesses",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RegistrationNumber",
                table: "Businesses",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "Businesses",
                type: "text",
                nullable: false,
                defaultValue: "Unverified");

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Businesses",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "Businesses",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "WebsiteUrl",
                table: "Businesses",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Businesses_RegistrationNumber",
                table: "Businesses",
                column: "RegistrationNumber");

            migrationBuilder.CreateIndex(
                name: "IX_Businesses_UserId",
                table: "Businesses",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Businesses_RegistrationNumber",
                table: "Businesses");

            migrationBuilder.DropIndex(
                name: "IX_Businesses_UserId",
                table: "Businesses");

            migrationBuilder.DropColumn(
                name: "Bio",
                table: "Businesses");

            migrationBuilder.DropColumn(
                name: "CoverPhotoUrl",
                table: "Businesses");

            migrationBuilder.DropColumn(
                name: "RegistrationNumber",
                table: "Businesses");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Businesses");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Businesses");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "Businesses");

            migrationBuilder.DropColumn(
                name: "WebsiteUrl",
                table: "Businesses");
        }
    }
}

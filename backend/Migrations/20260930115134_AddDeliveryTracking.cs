using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class AddDeliveryTracking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "CurrentLatitude",
                table: "Deliveries",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "CurrentLongitude",
                table: "Deliveries",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LocationUpdatedAt",
                table: "Deliveries",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Deliveries",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CurrentLatitude",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "CurrentLongitude",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "LocationUpdatedAt",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Deliveries");
        }
    }
}

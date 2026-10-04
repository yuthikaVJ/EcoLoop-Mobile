using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class AddMaterialListingImageUrls : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<List<string>>(
                name: "ImageUrls",
                table: "MaterialListings",
                type: "text[]",
                nullable: false,
                defaultValueSql: "'{}'");

            // Existing listings had a single photo: carry it over.
            migrationBuilder.Sql(
                """UPDATE "MaterialListings" SET "ImageUrls" = ARRAY["ImageUrl"] WHERE "ImageUrl" IS NOT NULL AND "ImageUrl" <> '';""");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ImageUrls",
                table: "MaterialListings");
        }
    }
}

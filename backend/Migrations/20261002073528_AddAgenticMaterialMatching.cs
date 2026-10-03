using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class AddAgenticMaterialMatching : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Availability",
                table: "MaterialListings",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Condition",
                table: "MaterialListings",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "MatchWorkflows",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ListingId = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerBusinessId = table.Column<Guid>(type: "uuid", nullable: false),
                    State = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    Outcome = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: true),
                    Reason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    StateHistoryJson = table.Column<string>(type: "jsonb", nullable: false),
                    TraceJson = table.Column<string>(type: "jsonb", nullable: true),
                    SuggestionCount = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MatchWorkflows", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MatchWorkflows_MaterialListings_ListingId",
                        column: x => x.ListingId,
                        principalTable: "MaterialListings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MatchSuggestions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    WorkflowId = table.Column<Guid>(type: "uuid", nullable: false),
                    HaveListingId = table.Column<Guid>(type: "uuid", nullable: false),
                    NeedListingId = table.Column<Guid>(type: "uuid", nullable: false),
                    Score = table.Column<decimal>(type: "numeric(4,3)", precision: 4, scale: 3, nullable: false),
                    Reasons = table.Column<List<string>>(type: "text[]", nullable: false),
                    Warnings = table.Column<List<string>>(type: "text[]", nullable: false),
                    QuantityCoverage = table.Column<decimal>(type: "numeric(4,3)", precision: 4, scale: 3, nullable: true),
                    DistanceKm = table.Column<double>(type: "double precision", nullable: true),
                    HaveOwnerDecision = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    NeedOwnerDecision = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MatchSuggestions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MatchSuggestions_MatchWorkflows_WorkflowId",
                        column: x => x.WorkflowId,
                        principalTable: "MatchWorkflows",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MatchSuggestions_MaterialListings_HaveListingId",
                        column: x => x.HaveListingId,
                        principalTable: "MaterialListings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MatchSuggestions_MaterialListings_NeedListingId",
                        column: x => x.NeedListingId,
                        principalTable: "MaterialListings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MatchSuggestions_HaveListingId_NeedListingId",
                table: "MatchSuggestions",
                columns: new[] { "HaveListingId", "NeedListingId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MatchSuggestions_NeedListingId",
                table: "MatchSuggestions",
                column: "NeedListingId");

            migrationBuilder.CreateIndex(
                name: "IX_MatchSuggestions_WorkflowId",
                table: "MatchSuggestions",
                column: "WorkflowId");

            migrationBuilder.CreateIndex(
                name: "IX_MatchWorkflows_ListingId_CreatedAt",
                table: "MatchWorkflows",
                columns: new[] { "ListingId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_MatchWorkflows_State_CreatedAt",
                table: "MatchWorkflows",
                columns: new[] { "State", "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MatchSuggestions");

            migrationBuilder.DropTable(
                name: "MatchWorkflows");

            migrationBuilder.DropColumn(
                name: "Availability",
                table: "MaterialListings");

            migrationBuilder.DropColumn(
                name: "Condition",
                table: "MaterialListings");
        }
    }
}

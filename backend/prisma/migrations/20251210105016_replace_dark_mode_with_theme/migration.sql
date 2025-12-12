/*
  Warnings:

  - You are about to drop the column `dark_mode` on the `user_settings` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "user_settings" DROP COLUMN "dark_mode",
ADD COLUMN     "theme" VARCHAR NOT NULL DEFAULT 'DARK';

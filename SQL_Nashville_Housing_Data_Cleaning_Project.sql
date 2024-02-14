/*
CLEANING DATA IN SQL QUERIES
*/

--------------------------------------------------------------------------------------------------------------------------------------

-- Observing the data

SELECT *
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data

--------------------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

-- WAY 1 (This may not work sometimes):
UPDATE SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data
SET SaleDate = CONVERT(date, SaleDate)

-- WAY 2 (Adding another date column that is standardized in the required format; this could be deleted later):
ALTER TABLE SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data
ADD StandardSaleDate Date

UPDATE SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data
SET StandardSaleDate = CONVERT(Date, SaleDate)

SELECT StandardSaleDate
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data


-----------------------------------------------------------------------------------------------------------------------------------------

--  Populate Property Address Data

SELECT *
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data

-- Idea:
-- Join rows with the same parcel id but with different unique ids
-- This is because same parcel ids have the same property address
-- Get the rows whose property address is null
-- Fill the propery address of those rows with the propery address corresponding to the common ParcelID
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data a
JOIN SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ] -- This part is to make sure you do not join same rows together
WHERE a.PropertyAddress IS NULL-- Get All the rows where the property address is null

UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data a
JOIN SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data b
ON a.ParcelID = b.ParcelID
AND a.uniqueID <> b.uniqueID
WHERE a.PropertyAddress IS NULL

SELECT PropertyAddress
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data
WHERE PropertyAddress IS NULL

-----------------------------------------------------------------------------------------------------------------------------------------

-- Breaking The Address Into Individual Columns (Address, City, State)

-- Observation: A comma seperates the address, city, and state of the PropertyAddress; 
--				There are no other punctuation within the address part of the PropertyAddress.

-- PropertyAddress has address and city name seperated by comma
SELECT PropertyAddress, SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AddressPartOfPropertyAddress,
	   SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) CityPartOfPropertyAddress
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data

-- Add new columns to table
ALTER TABLE SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data
ADD AddressPartOfPropertyAddress nvarchar(255),
	CityPartOfPropertyAddress nvarchar(255)

-- Fill the newly created columns
UPDATE housing
SET housing.AddressPartOfPropertyAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1), 
	housing.CityPartOfPropertyAddress =   SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data housing

-- Verify the newly created columns
SELECT AddressPartOfPropertyAddress, housing.CityPartOfPropertyAddress
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data housing

-- Let's also split the OwnerAddress column
SELECT OwnerAddress 
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data housing

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AddressPartOfOwnerAddress,
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) CityPartOfOwnerAddress,
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) StatePartOfOwnerAddress
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data

ALTER TABLE SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data
ADD AddressPartOfOwnerAddress nvarchar(255),
	CityPartOfOwnerAddress nvarchar(255),
	StatePartOfOwnerAddress nvarchar(255)

UPDATE housing
SET AddressPartOfOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	CityPartOfOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	StatePartOfOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data housing

SELECT AddressPartOfOwnerAddress, CityPartOfOwnerAddress, StatePartOfOwnerAddress
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data housing

-----------------------------------------------------------------------------------------------------------------------------------------

-- Chanding Y or N to Yes or No in "SoldAsVacant" field

SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data housing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant, 
	   CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
			END
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data

UPDATE SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
			END

SELECT DISTINCT(SoldAsVacant)
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data


-----------------------------------------------------------------------------------------------------------------------------------------

-- Deleting Duplicate rows

-- We assume that there cannot be two rows with the same ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
-- Because the same property with the same details cannot be sold twice on the same date
-- KEY: Use the ROW_NUMBER property

;WITH Finding_Duplicates_CTE AS(
SELECT *,
	   ROW_NUMBER () OVER
	   (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
		ORDER BY uniqueID) Row_Num_In_Partition
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data)
SELECT *  -- USE DELETE HERE WHILE DELETING
FROM Finding_Duplicates_CTE
WHERE Row_Num_In_Partition > 1


-----------------------------------------------------------------------------------------------------------------------------------------

-- Deleting Unused rows: SaleDate, TaxDistrict, PropertyAddress, OwnerAddress

ALTER TABLE SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data
DROP COLUMN SaleDate, TaxDistrict, PropertyAddress, OwnerAddress

SELECT *
FROM SQL_Nashville_Housing_Data_Cleaning_Project..Nashville_Housing_Data



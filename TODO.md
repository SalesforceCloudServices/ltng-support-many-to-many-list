# Overview

**-1. ensure relationships on the same object work**

**-1. support permissions to filter the relationships**

**-1. support filters on when to show relationships**

For example, use this relationship on this record type.

**1. Support multiple ways to sort**

Currently, we are running the list of records back, but we don't specify the fields to use for sorting.

**2. Support explicitly setting the fields to use**

Products currently aren't supported in the Mobile Experience.

Even if we show the products not from the detail but by using the [lightning:recordForm](https://developer.salesforce.com/docs/component-library/bundle/lightning:recordForm/documentation) - it isn't supported.

**3. Separate out the permission sets from an admin to a user**

Currently the demo person can see everything, and maybe we don't want that.

**4. Review the data and see if there are large numbers of child records**

Pagingation for child records may be necessary.

**5. Working with products on mobile**

Can be done by either a flow or formula fields to copy to the Opportunity Line Item, and then hiding the product on mobile.
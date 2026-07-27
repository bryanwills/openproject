//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

export function findIndex(el:HTMLElement):number {
  if (!el.parentElement) {
    return -1;
  }

  const children = Array.from(el.parentElement.children);
  return children.indexOf(el);
}

export function reinsert(el:HTMLElement, previousIndex:number|string, container:HTMLElement) {
  const prev = typeof previousIndex === 'string' ? parseInt(previousIndex, 10) : previousIndex;
  const currentIndex = el.parentNode ? Array.from(el.parentNode.children).indexOf(el) : null;
  const children = Array.from(container.children);

  const pointOfInsertion = (() => {
    if (currentIndex != null && currentIndex >= 0) {
      const isDraggingDown = currentIndex > prev;
      return isDraggingDown ? children[prev] : children[prev + 1];
    }

    return children[prev];
  })();

  if (pointOfInsertion) {
    container.insertBefore(el, pointOfInsertion);
  } else {
    container.appendChild(el);
  }
}
